#!/bin/bash
# Shared utilities for peter-terminal-utils install scripts
# This file is sourced by both the orchestrator (setup) and individual install scripts

###############################################################################
### Color Definitions
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

###############################################################################
### Logging Helpers
###############################################################################

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}○${NC} $1 (skipped)"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

###############################################################################
### Step/Run System - unified command execution with status tracking
###############################################################################
#
# Scripts using these helpers follow a BEST-EFFORT model:
#   - Individual step failures are logged but do NOT abort the script
#   - Use `step ... || exit 1` if a step is critical and must succeed
#   - The orchestrator (setup) continues to subsequent scripts even if one fails
#
# This allows partial installations to complete what they can, which is useful
# when some components require network access, sudo, or optional dependencies.

# State for grouped commands
STEP_FAILED=false
STEP_MSG=""

# Captured output from last _exec call (used for error display)
_EXEC_EXIT=0
_EXEC_OUT=""
_EXEC_ERR=""
_EXEC_STDIN=""  # Optional: set before _exec to provide stdin from file

### Core helper: run command, capture output, store in globals
### Returns the command's exit code
### Optional: set _EXEC_STDIN to a file path before calling to provide stdin
_exec() {
    local tmp_out tmp_err
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)
    if [ -n "${_EXEC_STDIN:-}" ]; then
        "$@" <"$_EXEC_STDIN" >"$tmp_out" 2>"$tmp_err"
    else
        "$@" >"$tmp_out" 2>"$tmp_err"
    fi
    _EXEC_EXIT=$?
    _EXEC_OUT=$(cat "$tmp_out")
    _EXEC_ERR=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    _EXEC_STDIN=""  # Reset after use
    # Log command execution if logging is enabled
    log_cmd "$@"
    return $_EXEC_EXIT
}

### Core helper: print error details from last _exec call
_print_error() {
    local cmd_desc="$1"
    echo -e "  ${RED}Failed:${NC} $cmd_desc (exit code: $_EXEC_EXIT)"

    # Log the error
    log "ERROR: $cmd_desc (exit $_EXEC_EXIT)"

    # Contextual suggestions based on common error patterns
    local combined_output="$_EXEC_OUT $_EXEC_ERR"
    case "$combined_output" in
        *"Permission denied"*)
            echo -e "  ${YELLOW}Suggestion:${NC} Try running with sudo, or check file/directory permissions" ;;
        *"not found"*|*"No such file"*|*"command not found"*)
            echo -e "  ${YELLOW}Suggestion:${NC} Ensure the file/command exists and PATH includes ~/.local/bin" ;;
        *"Connection refused"*|*"Could not resolve"*|*"Network is unreachable"*)
            echo -e "  ${YELLOW}Suggestion:${NC} Check your network connection and try again" ;;
        *"apt"*"lock"*|*"dpkg"*"lock"*)
            echo -e "  ${YELLOW}Suggestion:${NC} Another package manager may be running. Try: sudo rm /var/lib/dpkg/lock* /var/lib/apt/lists/lock" ;;
        *"ENOSPC"*|*"No space left"*)
            echo -e "  ${YELLOW}Suggestion:${NC} Disk is full. Free up space and try again" ;;
        *"rate limit"*|*"API rate"*)
            echo -e "  ${YELLOW}Suggestion:${NC} GitHub API rate limit hit. Wait a few minutes or set GITHUB_TOKEN" ;;
        *"certificate"*|*"SSL"*|*"TLS"*)
            echo -e "  ${YELLOW}Suggestion:${NC} SSL/TLS error. Check system time and ca-certificates package" ;;
    esac

    # Show truncated output (first 10 lines each)
    if [ -n "$_EXEC_OUT" ]; then
        echo -e "  ${RED}Stdout:${NC}"
        echo "$_EXEC_OUT" | head -10 | sed 's/^/    /'
        local out_lines
        out_lines=$(echo "$_EXEC_OUT" | wc -l)
        [ "$out_lines" -gt 10 ] && echo -e "    ${YELLOW}... ($((out_lines - 10)) more lines)${NC}"
    fi
    if [ -n "$_EXEC_ERR" ]; then
        echo -e "  ${RED}Stderr:${NC}"
        echo "$_EXEC_ERR" | head -10 | sed 's/^/    /'
        local err_lines
        err_lines=$(echo "$_EXEC_ERR" | wc -l)
        [ "$err_lines" -gt 10 ] && echo -e "    ${YELLOW}... ($((err_lines - 10)) more lines)${NC}"
    fi
}

### Single command with message - prints ✓ or ✗ when done
step() {
    local msg="$1"; shift
    
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${BLUE}ℹ${NC} [DRY RUN] $msg: $*"
        return 0
    fi
    
    printf "${CYAN}▶${NC} %s " "$msg"
    if _exec "$@"; then
        printf "\r\033[K"
        echo -e "${GREEN}✓${NC} $msg"
    else
        printf "\r\033[K"
        echo -e "${RED}✗${NC} $msg"
        _print_error "$*"
        return 1
    fi
}

### Begin a group of commands
step_start() {
    STEP_MSG="$1"
    STEP_FAILED=false
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${BLUE}ℹ${NC} [DRY RUN] $STEP_MSG"
    else
        printf "${CYAN}▶${NC} %s " "$STEP_MSG"
    fi
}

### Run a command within a group (silent on success, shows error on failure)
run() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "    ${BLUE}↳${NC} $*"
        return 0
    fi
    if ! _exec "$@"; then
        printf "\r\033[K"
        _print_error "$*"
        printf "${CYAN}▶${NC} %s " "$STEP_MSG"
        STEP_FAILED=true
    fi
}

### Run a command with stdin from a file
run_stdin() {
    local input_file="$1"; shift
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "    ${BLUE}↳${NC} $* < $input_file"
        return 0
    fi
    _EXEC_STDIN="$input_file"
    if ! _exec "$@"; then
        printf "\r\033[K"
        _print_error "$* < $input_file"
        printf "${CYAN}▶${NC} %s " "$STEP_MSG"
        STEP_FAILED=true
    fi
}

### End a group - prints ✓ or ✗ based on whether any command failed
step_end() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi
    printf "\r\033[K"
    if [[ "$STEP_FAILED" == true ]]; then
        echo -e "${RED}✗${NC} $STEP_MSG"
        return 1
    else
        echo -e "${GREEN}✓${NC} $STEP_MSG"
    fi
}

###############################################################################
### Helper Functions
###############################################################################

### Skip script entirely if running in headless mode
### Usage: skip_if_headless "Script Name"
skip_if_headless() {
    local name="$1"
    if [[ "$HEADLESS" == "Y" ]]; then
        print_skip "$name (headless mode)"
        exit 0
    fi
}

### Install a command if not already present
### Optional 4th param "sudo" skips if HAS_SUDO=false
ensure_command() {
    local name="$1"
    local cmd="$2"
    local install_func="$3"
    local needs_sudo="${4:-}"
    
    if [[ "$needs_sudo" == "sudo" && "${HAS_SUDO:-false}" == false ]]; then
        print_skip "$name (requires sudo)"
        return
    fi
    
    if ! command -v "$cmd" &> /dev/null; then
        step "Installing $name" "$install_func"
    else
        print_skip "$name already installed"
    fi
}

### Run something only if sudo is available, otherwise skip with message
require_sudo() {
    local msg="$1"; shift
    if [[ "${HAS_SUDO:-false}" == true ]]; then
        "$@"
    else
        print_skip "$msg (requires sudo)"
    fi
}

### Helper function for Y/N prompts
prompt_yn() {
    local prompt="$1"
    local default="$2"
    local response
    read -r -p "$prompt " response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy] ]]
}

### Helper function for text input prompts
prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    read -r -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

### Get latest version from GitHub releases (uses redirect, not API - avoids rate limits)
### Usage: version=$(github_latest_version "owner/repo") || return 1
github_latest_version() {
    local repo="$1"
    local redirect_url version
    # Use HEAD request to get redirect URL - this doesn't hit API rate limits
    redirect_url=$(curl -sI "https://github.com/${repo}/releases/latest" 2>&1 | grep -i '^location:' | tr -d '\r') || {
        echo "Failed to fetch release redirect for $repo" >&2
        return 1
    }
    if [ -z "$redirect_url" ]; then
        echo "No redirect found for $repo releases" >&2
        return 1
    fi
    # Extract version from URL like: .../releases/tag/v1.2.3 or .../releases/tag/1.2.3
    version=$(echo "$redirect_url" | grep -oP '/tag/v?\K[^/\s]+$') || {
        echo "Failed to parse version from redirect URL: $redirect_url" >&2
        return 1
    }
    echo "$version"
}

###############################################################################
### Architecture Detection
###############################################################################

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

###############################################################################
### Distro Detection
###############################################################################

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
# shellcheck source=/dev/null
DISTRO_VERSION=$(. /etc/os-release 2>/dev/null && echo "${VERSION_ID:-}" || echo "")

is_ubuntu() { [[ "$DISTRO" == "ubuntu" ]]; }
is_debian() { [[ "$DISTRO" == "debian" ]]; }
is_fedora() { [[ "$DISTRO" == "fedora" ]]; }
is_arch() { [[ "$DISTRO" == "arch" ]]; }
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }
is_wsl2() { is_wsl && grep -qi "wsl2" /proc/version 2>/dev/null; }

###############################################################################
### GitHub Release Architecture Mapping
###############################################################################

# Maps tool name to its GitHub release architecture suffix
# Usage: arch_suffix=$(get_release_arch "bat")
get_release_arch() {
    local tool="$1"
    case "$tool" in
        # Standard Rust musl/gnu builds (most tools)
        bat|fd|delta|eza|bottom)
            case "$ARCH" in
                x86_64) echo "x86_64-unknown-linux-musl" ;;
                arm64)  echo "aarch64-unknown-linux-gnu" ;;
            esac ;;
        # btop uses musl for both architectures
        btop)
            case "$ARCH" in
                x86_64) echo "x86_64-unknown-linux-musl" ;;
                arm64)  echo "aarch64-unknown-linux-musl" ;;
            esac ;;
        # lazygit uses different naming convention
        lazygit)
            case "$ARCH" in
                x86_64) echo "Linux_x86_64" ;;
                arm64)  echo "Linux_arm64" ;;
            esac ;;
        *)
            echo "Unknown tool for arch mapping: $tool" >&2
            return 1 ;;
    esac
}

###############################################################################
### Generic GitHub Binary Installer
###############################################################################

# Install a binary from GitHub releases
# Usage: install_github_binary "owner/repo" "tool_name" [binary_name] [strip_components]
#   - owner/repo: GitHub repository (e.g., "sharkdp/bat")
#   - tool_name: Tool name for arch lookup and tarball naming
#   - binary_name: Name of binary inside archive (defaults to tool_name)
#   - strip_components: tar --strip-components value (default: 1)
#       Use 0 for flat archives where the binary is at the archive root
#       Use 1 for archives with a single top-level directory (most common)
install_github_binary() {
    local repo="$1"
    local tool="$2"
    local binary="${3:-$tool}"
    local strip="${4:-1}"

    local version arch_suffix tmpdir archive_url

    version=$(github_latest_version "$repo") || return 1
    arch_suffix=$(get_release_arch "$tool") || return 1

    tmpdir=$(mktemp -d)

    # Cleanup function - called by trap or explicitly on success
    _cleanup_tmpdir() { rm -rf "$tmpdir"; }
    trap _cleanup_tmpdir EXIT TERM INT

    # Common URL patterns - try different naming conventions
    local base_url="https://github.com/$repo/releases/download"
    local patterns=(
        # v-prefixed tag, v-prefixed filename: bat-v0.24.0-x86_64-...
        "$base_url/v${version}/${tool}-v${version}-${arch_suffix}.tar.gz"
        # v-prefixed tag, no v in filename: some tools
        "$base_url/v${version}/${tool}-${version}-${arch_suffix}.tar.gz"
        # No v-prefix in tag, no v in filename: delta-0.18.2-x86_64-...
        "$base_url/${version}/${tool}-${version}-${arch_suffix}.tar.gz"
        # lazygit style: lazygit_0.44.1_Linux_x86_64.tar.gz
        "$base_url/v${version}/${tool}_${version}_${arch_suffix}.tar.gz"
        # eza style: eza_x86_64-unknown-linux-musl.tar.gz (no version in filename)
        "$base_url/v${version}/${tool}_${arch_suffix}.tar.gz"
        # bottom style (no v-prefix): bottom_x86_64-unknown-linux-musl.tar.gz
        "$base_url/${version}/${tool}_${arch_suffix}.tar.gz"
        # btop style: btop-x86_64-linux-musl.tbz
        "$base_url/v${version}/${tool}-${arch_suffix}.tbz"
    )

    archive_url=""
    for pattern in "${patterns[@]}"; do
        if curl -fsSL --head "$pattern" &>/dev/null; then
            archive_url="$pattern"
            break
        fi
    done

    if [ -z "$archive_url" ]; then
        echo "Could not find release URL for $tool v$version" >&2
        return 1
    fi

    # Download archive
    local archive_file="$tmpdir/archive"
    if ! curl -fsSL -o "$archive_file" "$archive_url"; then
        return 1
    fi

    # Extract based on extension
    local extract_ok=false
    case "$archive_url" in
        *.tar.gz|*.tgz)
            tar xzf "$archive_file" -C "$tmpdir" --strip-components="$strip" && extract_ok=true
            ;;
        *.tbz|*.tar.bz2)
            tar xjf "$archive_file" -C "$tmpdir" --strip-components="$strip" && extract_ok=true
            ;;
        *.zip)
            unzip -q "$archive_file" -d "$tmpdir" && extract_ok=true
            ;;
        *)
            echo "Unknown archive format: $archive_url" >&2
            ;;
    esac

    if [ "$extract_ok" != "true" ]; then
        return 1
    fi

    # Find and install the binary
    mkdir -p "$HOME/.local/bin"
    local found_binary
    found_binary=$(find "$tmpdir" -name "$binary" -type f -executable 2>/dev/null | head -1)
    if [ -z "$found_binary" ]; then
        # Try without executable check (might need to chmod)
        found_binary=$(find "$tmpdir" -name "$binary" -type f 2>/dev/null | head -1)
    fi

    if [ -z "$found_binary" ]; then
        echo "Binary '$binary' not found in archive" >&2
        return 1
    fi

    install -m 755 "$found_binary" "$HOME/.local/bin/$binary"

    # Cleanup and clear trap on success
    _cleanup_tmpdir
    trap - EXIT TERM INT
}

###############################################################################
### Persistent Logging
###############################################################################

LOG_DIR="$HOME/.config/peter-terminal-utils/logs"
LOG_FILE=""

# Initialize logging - call once at script start
init_logging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
    {
        echo "=== Installation started at $(date -Iseconds) ==="
        echo "Distro: $DISTRO $DISTRO_VERSION | Arch: $ARCH | WSL: $(is_wsl && echo yes || echo no)"
        echo "User: $USER | Home: $HOME"
        echo "==="
    } >> "$LOG_FILE"
}

# Log a message to the log file
log() {
    [ -n "$LOG_FILE" ] && echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"
}

# Log command execution details (called after _exec)
log_cmd() {
    if [ -n "$LOG_FILE" ]; then
        {
            echo "[$(date +%H:%M:%S)] CMD: $*"
            echo "  EXIT: $_EXEC_EXIT"
            [ -n "$_EXEC_ERR" ] && echo "  STDERR: $_EXEC_ERR" | head -5
        } >> "$LOG_FILE"
    fi
}

###############################################################################
### Path Helpers
###############################################################################

# Get the linux directory (two levels up from any install script)
# Usage: LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")
#   - caller_script: Path to the calling script (use ${BASH_SOURCE[0]} at call site)
#     Falls back to BASH_SOURCE[1] if not provided, but explicit is safer.
get_linux_dir() {
    local caller_script="${1:-${BASH_SOURCE[1]}}"
    cd "$(dirname "$caller_script")/../.." && pwd
}

###############################################################################
### Script Metadata
###############################################################################

# Extract metadata from a script file
# Usage: value=$(get_script_meta "/path/to/script.sh" "key")
# Returns empty string if key not found
get_script_meta() {
    local script="$1" key="$2"
    grep -m1 "^# @${key}:" "$script" 2>/dev/null | sed "s/^# @${key}:[[:space:]]*//"
}

# Check if script requires sudo (looks for @requires: sudo)
script_requires_sudo() {
    local script="$1"
    local requires
    requires=$(get_script_meta "$script" "requires")
    [[ "$requires" == *"sudo"* ]]
}

# Check if script can run in parallel
script_is_parallel() {
    local script="$1"
    [[ "$(get_script_meta "$script" "parallel")" == "true" ]]
}

###############################################################################
### Standalone Script Support
###############################################################################

# Read a value from config.toml using grep/sed (no external dependencies)
# Usage: value=$(read_config_value "section.key")
_read_config_value() {
    local key="$1"
    local config_file
    # Config is in the linux directory (same level as _common.sh)
    config_file="$(dirname "${BASH_SOURCE[0]}")/config.toml"
    [ -f "$config_file" ] || return 1
    # Simple TOML parser: find key = "value" and extract value
    grep -E "^${key}\s*=" "$config_file" 2>/dev/null | sed -E 's/^[^=]+=[[:space:]]*"([^"]+)".*/\1/' | head -1
}

# When running standalone (not orchestrated), prompt for missing config
standalone_init() {
    if [[ "${ORCHESTRATED:-}" == "true" ]]; then
        return 0
    fi
    
    # Running standalone - set defaults or prompt
    : "${DRY_RUN:=false}"
    
    if [[ -z "${HEADLESS:-}" ]]; then
        if prompt_yn "Headless mode (skip GUI packages)? [y/N]" "N"; then
            HEADLESS="Y"
        else
            HEADLESS="N"
        fi
    fi
    
    if [[ -z "${HAS_SUDO:-}" ]]; then
        if sudo -n true 2>/dev/null; then
            HAS_SUDO=true
        elif [[ $EUID -eq 0 ]]; then
            HAS_SUDO=true
        else
            if prompt_yn "Authenticate with sudo? [Y/n]" "Y"; then
                if sudo -v; then
                    HAS_SUDO=true
                else
                    HAS_SUDO=false
                fi
            else
                HAS_SUDO=false
            fi
        fi
    fi
    
    # Read defaults from config.toml
    local default_git_name default_git_email
    default_git_name=$(_read_config_value "git_name") || default_git_name="Your Name"
    default_git_email=$(_read_config_value "git_email") || default_git_email="you@example.com"
    
    if [[ -z "${GIT_NAME:-}" ]]; then
        GIT_NAME=$(prompt_input "Git user name" "$default_git_name")
    fi
    
    if [[ -z "${GIT_EMAIL:-}" ]]; then
        GIT_EMAIL=$(prompt_input "Git email" "$default_git_email")
    fi
    
    # Export for any child processes
    export DRY_RUN HEADLESS HAS_SUDO GIT_NAME GIT_EMAIL
}

