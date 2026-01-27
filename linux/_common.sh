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
### PATH Setup - Ensure common tool directories are available
###############################################################################
# Tools like uv, cargo, and GitHub binaries install to these directories.
# Adding them early ensures dependent scripts can find newly-installed tools.

[[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]] && export PATH="$HOME/.cargo/bin:$PATH"

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
###
### Modes:
###   - Default: Capture output silently, show only on error (clean TUI)
###   - STREAM_OUTPUT=true: Stream output live AND capture (for TUI live panel)
_exec() {
    local tmp_out tmp_err
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)
    
    if [[ "${STREAM_OUTPUT:-false}" == true ]]; then
        # Streaming mode: show output live while also capturing for error display
        # Run command, tee stdout/stderr to temp files, display with indent
        # Use a subshell to isolate pipefail setting
        (
            set -o pipefail
            if [ -n "${_EXEC_STDIN:-}" ]; then
                "$@" <"$_EXEC_STDIN" 2>&1 | tee "$tmp_out" | sed 's/^/    /'
            else
                "$@" 2>&1 | tee "$tmp_out" | sed 's/^/    /'
            fi
        )
        _EXEC_EXIT=$?
        # In streaming mode, stderr is merged into stdout (tee'd to tmp_out)
        # Copy to tmp_err for consistency with error display code
        cp "$tmp_out" "$tmp_err"
    else
        # Silent capture mode: only display on error
        if [ -n "${_EXEC_STDIN:-}" ]; then
            "$@" <"$_EXEC_STDIN" >"$tmp_out" 2>"$tmp_err"
        else
            "$@" >"$tmp_out" 2>"$tmp_err"
        fi
        _EXEC_EXIT=$?
    fi
    
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
        *"dpkg was interrupted"*|*"dpkg --configure -a"*)
            echo -e "  ${YELLOW}Suggestion:${NC} Previous package operation was interrupted. Fix with: sudo dpkg --configure -a" ;;
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
    
    echo -e "${CYAN}▶${NC} $msg"
    echo -e "  ${CYAN}\$${NC} $*"
    if _exec "$@"; then
        echo -e "${GREEN}✓${NC} $msg"
    else
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
        echo -e "${CYAN}▶${NC} $STEP_MSG"
    fi
}

### Run a command within a group (silent on success, shows error on failure)
run() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "    ${BLUE}↳${NC} $*"
        return 0
    fi
    echo -e "  ${CYAN}\$${NC} $*"
    if ! _exec "$@"; then
        _print_error "$*"
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
    echo -e "  ${CYAN}\$${NC} $* < $input_file"
    _EXEC_STDIN="$input_file"
    if ! _exec "$@"; then
        _print_error "$* < $input_file"
        STEP_FAILED=true
    fi
}

### End a group - prints ✓ or ✗ based on whether any command failed
step_end() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi
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

### Skip script entirely if running in headless mode or WSL
### WSL is treated as headless since GUI apps should use Windows host versions
### Usage: skip_if_headless "Script Name"
skip_if_headless() {
    local name="$1"
    if [[ "$HEADLESS" == "Y" ]]; then
        print_skip "$name (headless mode)"
        exit 0
    fi
    if is_wsl; then
        print_skip "$name (WSL - use Windows version)"
        exit 0
    fi
}

### Skip script entirely if running in WSL (but allow headless)
### Use this for scripts that work on headless servers but not WSL (e.g., NVIDIA drivers)
### Usage: skip_if_wsl "Script Name"
skip_if_wsl() {
    local name="$1"
    if is_wsl; then
        print_skip "$name (WSL - use Windows version)"
        exit 0
    fi
}

### Install a command if not already present (LEGACY - prefer ensure_github_tool)
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
        step "Installing $name" eval "$install_func"
    else
        print_skip "$name already installed"
    fi
}

### Install/update a tool from GitHub releases with version checking
### Compares installed version against latest GitHub release, updates if outdated
### Usage: ensure_github_tool "owner/repo" "tool_name" [binary_name] [strip_components]
ensure_github_tool() {
    local repo="$1"
    local tool="$2"
    local binary="${3:-$tool}"
    local strip="${4:-1}"

    if command -v "$binary" &>/dev/null; then
        local installed latest
        installed=$(get_installed_version "$binary") || installed=""
        latest=$(github_latest_version "$repo") || {
            print_warning "Cannot check $tool version (network?)"
            return 0
        }

        if [[ -n "$installed" ]]; then
            semver_compare "$installed" "$latest"
            case $? in
                0) print_skip "$tool at latest ($installed)"; return 0 ;;
                2) print_skip "$tool newer than release ($installed > $latest)"; return 0 ;;
                1) print_info "$tool: $installed -> $latest" ;;
            esac
        fi
    fi

    step "Installing $tool" install_github_binary "$repo" "$tool" "$binary" "$strip"
}

### Clone a git repo if missing, pull if exists
### For tools installed via git clone (oh-my-zsh, zsh plugins, powerlevel10k)
### Usage: ensure_git_repo "https://github.com/user/repo.git" "/dest/path" [name]
ensure_git_repo() {
    local url="$1"
    local dest="$2"
    local name="${3:-$(basename "$url" .git)}"

    if [[ -d "$dest/.git" ]]; then
        step "Updating $name" git -C "$dest" pull --ff-only
    else
        # Remove incomplete clone if present
        rm -rf "$dest"
        step "Cloning $name" git clone --depth=1 "$url" "$dest"
    fi
}

### Install/update a GNOME Shell extension from extensions.gnome.org
### Uses --force flag which handles both install and update
### Usage: ensure_gnome_extension "extension-uuid@author" [display_name]
ensure_gnome_extension() {
    local uuid="$1"
    local name="${2:-$uuid}"

    # Skip if gnome-extensions command not available
    command -v gnome-extensions &>/dev/null || {
        print_skip "$name (gnome-extensions unavailable)"
        return 0
    }

    local shell_ver download_url tmpzip api_resp

    shell_ver=$(gnome-shell --version 2>/dev/null | grep -oP '\d+' | head -1) || {
        print_warning "Cannot determine GNOME Shell version"
        return 1
    }

    api_resp=$(curl -sf --connect-timeout 10 \
        "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_ver") || {
        print_warning "Cannot fetch $name info from extensions.gnome.org"
        return 1
    }

    download_url=$(echo "$api_resp" | jq -r '.download_url // empty')
    [[ -n "$download_url" ]] || {
        print_warning "$name not available for GNOME Shell $shell_ver"
        return 1
    }

    tmpzip=$(mktemp --suffix=.zip)
    if ! curl -sfL "https://extensions.gnome.org$download_url" -o "$tmpzip"; then
        rm -f "$tmpzip"
        return 1
    fi

    # --force handles both install and update
    step "Installing/updating $name" gnome-extensions install --force "$tmpzip"
    local result=$?
    rm -f "$tmpzip"
    return $result
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

###############################################################################
### Semver Utilities - Version extraction and comparison per semver.org spec
###############################################################################

### Extract semver from command's --version output
### Strips ANSI codes, finds first semver-like match, normalizes
### Returns: X.Y.Z or X.Y.Z-prerelease (build metadata stripped for comparison)
### Usage: version=$(get_installed_version "binary_name")
get_installed_version() {
    local binary="$1"
    local output version

    # Get version output, strip ANSI escape codes (handles btop's colored output)
    output=$("$binary" --version 2>&1 | head -10 | sed 's/\x1b\[[0-9;]*m//g') || return 1

    # Extract first semver-like match: v?X.Y.Z with optional pre-release suffix
    # Handles formats like:
    #   "bat 0.26.1 (979ba22)"     -> 0.26.1
    #   "v0.23.4 [+git]"           -> 0.23.4
    #   "1.4.6+e969f43"            -> 1.4.6
    #   "NVIM v0.10.4"             -> 0.10.4
    #   "version=0.57.0"           -> 0.57.0
    #   "0.60 (devel)"             -> 0.60.0 (normalized)
    version=$(echo "$output" | grep -oP 'v?(0|[1-9]\d*)\.(0|[1-9]\d*)(\.(0|[1-9]\d*))?(-[0-9A-Za-z.-]+)?' | head -1)

    # Normalize: strip v prefix
    version="${version#v}"

    # Strip build metadata (everything after +) for comparison purposes
    version="${version%+*}"

    # If only X.Y format (like fzf "0.60"), append .0 to normalize to X.Y.Z
    if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        version="${version}.0"
    fi

    # Return empty string instead of partial match if no valid version found
    [[ -z "$version" ]] && return 1

    echo "$version"
}

### Compare two semver strings per semver.org spec (section 11)
### Returns: 0 if v1 == v2, 1 if v1 < v2, 2 if v1 > v2
### Handles: X.Y.Z, pre-release (-alpha.1), ignores build metadata (+sha)
### Usage: semver_compare "1.0.0" "2.0.0"; case $? in 0) equal ;; 1) less ;; 2) greater ;; esac
semver_compare() {
    local v1="$1" v2="$2"

    # Strip build metadata (ignored for precedence per spec section 10)
    v1="${v1%+*}"
    v2="${v2%+*}"

    # Strip v prefix if present (common in git tags)
    v1="${v1#v}"
    v2="${v2#v}"

    # Equal check (fast path)
    [[ "$v1" == "$v2" ]] && return 0

    # Split into core (X.Y.Z) and pre-release (-alpha.1)
    local v1_core="${v1%%-*}" v1_pre="" v2_core="${v2%%-*}" v2_pre=""
    [[ "$v1" == *-* ]] && v1_pre="${v1#*-}"
    [[ "$v2" == *-* ]] && v2_pre="${v2#*-}"

    # Compare core version (X.Y.Z) numerically
    local IFS='.'
    # shellcheck disable=SC2206  # Intentional word splitting on IFS
    local -a c1=($v1_core) c2=($v2_core)
    local i
    for ((i=0; i<3; i++)); do
        local n1="${c1[i]:-0}" n2="${c2[i]:-0}"
        ((n1 < n2)) && return 1
        ((n1 > n2)) && return 2
    done

    # Core versions equal - check pre-release
    # Per spec section 11.3: version without pre-release > version with pre-release
    [[ -z "$v1_pre" && -n "$v2_pre" ]] && return 2  # 1.0.0 > 1.0.0-alpha
    [[ -n "$v1_pre" && -z "$v2_pre" ]] && return 1  # 1.0.0-alpha < 1.0.0
    [[ -z "$v1_pre" && -z "$v2_pre" ]] && return 0  # Both no pre-release

    # Both have pre-release - compare dot-separated identifiers per spec section 11.4
    _semver_compare_prerelease "$v1_pre" "$v2_pre"
}

### Compare pre-release identifiers per semver spec section 11.4
### Called by semver_compare when both versions have pre-release suffixes
_semver_compare_prerelease() {
    local p1="$1" p2="$2"
    local IFS='.'
    # shellcheck disable=SC2206  # Intentional word splitting on IFS
    local -a ids1=($p1) ids2=($p2)
    local i len1=${#ids1[@]} len2=${#ids2[@]}
    local max=$((len1 > len2 ? len1 : len2))

    for ((i=0; i<max; i++)); do
        local id1="${ids1[i]:-}" id2="${ids2[i]:-}"

        # Spec 11.4.4: Fewer identifiers = lower precedence (if all preceding equal)
        [[ -z "$id1" && -n "$id2" ]] && return 1
        [[ -n "$id1" && -z "$id2" ]] && return 2

        # Spec 11.4.1: Both numeric - compare numerically
        if [[ "$id1" =~ ^[0-9]+$ && "$id2" =~ ^[0-9]+$ ]]; then
            ((id1 < id2)) && return 1
            ((id1 > id2)) && return 2
        # Spec 11.4.3: Numeric identifiers < non-numeric identifiers
        elif [[ "$id1" =~ ^[0-9]+$ ]]; then
            return 1
        elif [[ "$id2" =~ ^[0-9]+$ ]]; then
            return 2
        # Spec 11.4.2: Both non-numeric - compare lexically in ASCII sort order
        else
            [[ "$id1" < "$id2" ]] && return 1
            [[ "$id1" > "$id2" ]] && return 2
        fi
    done
    return 0
}

### Run semver comparison tests against spec examples
### Call with: _test_semver (for development/CI validation)
_test_semver() {
    local -a tests=(
        # From semver.org spec section 11.2 - basic version ordering
        "1.0.0:2.0.0:1"      # 1.0.0 < 2.0.0
        "2.0.0:2.1.0:1"      # 2.0.0 < 2.1.0
        "2.1.0:2.1.1:1"      # 2.1.0 < 2.1.1
        # Spec section 11.3 - pre-release has lower precedence than release
        "1.0.0-alpha:1.0.0:1"
        # Spec section 11.4 - pre-release version ordering (from spec example)
        "1.0.0-alpha:1.0.0-alpha.1:1"
        "1.0.0-alpha.1:1.0.0-alpha.beta:1"
        "1.0.0-alpha.beta:1.0.0-beta:1"
        "1.0.0-beta:1.0.0-beta.2:1"
        "1.0.0-beta.2:1.0.0-beta.11:1"
        "1.0.0-beta.11:1.0.0-rc.1:1"
        "1.0.0-rc.1:1.0.0:1"
        # Spec section 10 - build metadata ignored for precedence
        "1.0.0+build1:1.0.0+build2:0"
        "1.0.0+abc:1.0.0:0"
        "1.0.0-alpha+001:1.0.0-alpha+002:0"
        # Equality tests
        "1.0.0:1.0.0:0"
        "1.0.0-alpha:1.0.0-alpha:0"
        # Reverse direction tests (v1 > v2 should return 2)
        "2.0.0:1.0.0:2"
        "1.0.0:1.0.0-alpha:2"
        # v prefix handling
        "v1.0.0:1.0.0:0"
        "v1.0.0:v1.0.0:0"
    )
    local passed=0 failed=0
    for test in "${tests[@]}"; do
        IFS=':' read -r v1 v2 expected <<< "$test"
        semver_compare "$v1" "$v2"
        local result=$?
        if [[ "$result" == "$expected" ]]; then
            echo -e "${GREEN}✓${NC} $v1 vs $v2 = $result"
            ((passed++))
        else
            echo -e "${RED}✗${NC} $v1 vs $v2 = $result (expected $expected)"
            ((failed++))
        fi
    done
    echo ""
    echo "Passed: $passed, Failed: $failed"
    [[ $failed -eq 0 ]]
}

### Get latest version from GitHub releases (uses redirect, not API - avoids rate limits)
### Usage: version=$(github_latest_version "owner/repo") || return 1
github_latest_version() {
    local repo="$1"
    local redirect_url version curl_output
    
    # Use HEAD request to get redirect URL - this doesn't hit API rate limits
    # Capture both stdout and stderr for better diagnostics
    curl_output=$(curl -sI --connect-timeout 10 "https://github.com/${repo}/releases/latest" 2>&1) || {
        echo "Failed to connect to GitHub for $repo: $curl_output" >&2
        return 1
    }
    redirect_url=$(echo "$curl_output" | grep -i '^location:' | tr -d '\r')
    if [ -z "$redirect_url" ]; then
        echo "No redirect found for $repo releases (check network or repo existence)" >&2
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
# WSL2 detection: check for WSL_INTEROP (set by WSL2), or fall back to version string
is_wsl2() {
    is_wsl || return 1
    # WSL_INTEROP is only set in WSL2
    [[ -n "${WSL_INTEROP:-}" ]] && return 0
    # Fallback: check /proc/version for wsl2 marker
    grep -qi "wsl2" /proc/version 2>/dev/null && return 0
    # Another fallback: WSL2 uses kernel >= 5.x with microsoft in version
    grep -qP "Linux version [5-9]\.\d+.*[Mm]icrosoft" /proc/version 2>/dev/null
}

###############################################################################
### Desktop Environment Detection
###############################################################################

detect_desktop() {
    case "${XDG_CURRENT_DESKTOP:-}" in
        *GNOME*|*Unity*) echo "gnome" ;;
        *KDE*|*Plasma*) echo "kde" ;;
        *XFCE*) echo "xfce" ;;
        *Cinnamon*) echo "cinnamon" ;;
        *MATE*) echo "mate" ;;
        *) echo "unknown" ;;
    esac
}

DESKTOP_ENV=$(detect_desktop)

is_gnome() { [[ "$DESKTOP_ENV" == "gnome" ]]; }
is_kde() { [[ "$DESKTOP_ENV" == "kde" ]]; }
is_cinnamon() { [[ "$DESKTOP_ENV" == "cinnamon" ]]; }
is_gnome_shell() { command -v gnome-shell &>/dev/null; }

### Skip script if not running GNOME desktop
### Usage: skip_if_not_gnome "Script Name"
skip_if_not_gnome() {
    local name="$1"
    if ! is_gnome; then
        print_skip "$name (requires GNOME desktop)"
        exit 0
    fi
}

### Skip script if not running GNOME Shell (stricter than skip_if_not_gnome)
### Usage: skip_if_not_gnome_shell "Script Name"
skip_if_not_gnome_shell() {
    local name="$1"
    if ! is_gnome_shell; then
        print_skip "$name (requires GNOME Shell)"
        exit 0
    fi
}

###############################################################################
### Package Manager Detection
###############################################################################

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v zypper &>/dev/null; then echo "zypper"
    else echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

# Lock file for serializing package manager operations
# Prevents race conditions when multiple scripts call pkg_install concurrently
PKG_LOCK="/tmp/peter-terminal-utils-pkg.lock"

# Timeout (seconds) for apt to wait for dpkg lock
# Handles cases where PackageKit or other apt processes temporarily hold the lock
APT_LOCK_TIMEOUT=120

### Execute a command while holding the package manager lock
### Uses flock to serialize access - blocks until lock is available
### Usage: with_pkg_lock command args...
with_pkg_lock() {
    (
        flock -x 200
        "$@"
    ) 200>"$PKG_LOCK"
}

### Check if dpkg is in a consistent state (apt-based distros only)
### Returns 0 if OK, 1 if needs repair
### Usage: pkg_check_health || { echo "Fix with: sudo dpkg --configure -a"; exit 1; }
pkg_check_health() {
    if [[ "$PKG_MANAGER" != "apt" ]]; then
        return 0  # Only applies to apt-based distros
    fi
    # Check if dpkg has pending configurations
    if sudo dpkg --audit 2>&1 | grep -q .; then
        echo -e "${RED}✗${NC} Package database is inconsistent" >&2
        echo -e "  ${YELLOW}Fix with:${NC} sudo dpkg --configure -a" >&2
        return 1
    fi
    return 0
}

### Install packages using the detected package manager
### Automatically serialized via flock to prevent concurrent apt/dnf conflicts
### Usage: pkg_install package1 package2 ...
pkg_install() {
    with_pkg_lock _pkg_install_impl "$@"
}

_pkg_install_impl() {
    case "$PKG_MANAGER" in
        apt) sudo apt-get -o DPkg::Lock::Timeout="$APT_LOCK_TIMEOUT" install -yq "$@" ;;
        dnf) sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
        zypper) sudo zypper install -y "$@" ;;
        *) echo "Unsupported package manager: $PKG_MANAGER" >&2; return 1 ;;
    esac
}

### Update package manager cache
### Automatically serialized via flock to prevent concurrent conflicts
### Usage: pkg_update
pkg_update() {
    with_pkg_lock _pkg_update_impl
}

_pkg_update_impl() {
    case "$PKG_MANAGER" in
        apt) sudo apt-get -o DPkg::Lock::Timeout="$APT_LOCK_TIMEOUT" update -qq ;;
        dnf) sudo dnf check-update || true ;;  # Returns 100 if updates available
        pacman) sudo pacman -Sy ;;
        zypper) sudo zypper refresh ;;
        *) echo "Unsupported package manager: $PKG_MANAGER" >&2; return 1 ;;
    esac
}

### Upgrade all packages
### Automatically serialized via flock to prevent concurrent conflicts
### Usage: pkg_upgrade
pkg_upgrade() {
    with_pkg_lock _pkg_upgrade_impl
}

_pkg_upgrade_impl() {
    case "$PKG_MANAGER" in
        apt) sudo apt-get -o DPkg::Lock::Timeout="$APT_LOCK_TIMEOUT" upgrade -yq ;;
        dnf) sudo dnf upgrade -y ;;
        pacman) sudo pacman -Su --noconfirm ;;
        zypper) sudo zypper update -y ;;
        *) echo "Unsupported package manager: $PKG_MANAGER" >&2; return 1 ;;
    esac
}

### Remove packages that were installed as dependencies but are no longer needed
### Usage: pkg_autoremove
pkg_autoremove() {
    with_pkg_lock _pkg_autoremove_impl
}

_pkg_autoremove_impl() {
    case "$PKG_MANAGER" in
        apt) sudo apt-get -o DPkg::Lock::Timeout="$APT_LOCK_TIMEOUT" autoremove -yq ;;
        dnf) sudo dnf autoremove -y ;;
        pacman)
            # Remove orphaned packages if any exist
            local orphans
            orphans=$(pacman -Qdtq 2>/dev/null) || true
            if [[ -n "$orphans" ]]; then
                echo "$orphans" | sudo pacman -Rs --noconfirm -
            fi
            ;;
        zypper)
            # zypper doesn't have autoremove; remove unneeded packages if any
            local unneeded
            unneeded=$(zypper packages --unneeded 2>/dev/null | awk -F'|' 'NR>4 && NF>2 {gsub(/^ +| +$/, "", $3); if ($3 != "") print $3}') || true
            if [[ -n "$unneeded" ]]; then
                sudo zypper remove -y $unneeded
            fi
            ;;
        *) echo "Unsupported package manager: $PKG_MANAGER" >&2; return 1 ;;
    esac
}

### Clear the package manager cache to reclaim disk space
### Usage: pkg_clean
pkg_clean() {
    with_pkg_lock _pkg_clean_impl
}

_pkg_clean_impl() {
    case "$PKG_MANAGER" in
        apt) sudo apt-get -o DPkg::Lock::Timeout="$APT_LOCK_TIMEOUT" clean ;;
        dnf) sudo dnf clean all ;;
        pacman) sudo pacman -Sc --noconfirm ;;
        zypper) sudo zypper clean --all ;;
        *) echo "Unsupported package manager: $PKG_MANAGER" >&2; return 1 ;;
    esac
}

### Install a local package file (.deb, .rpm, .pkg.tar.zst)
### Automatically serialized via flock to prevent concurrent conflicts
### Usage: pkg_install_local /path/to/package.deb
pkg_install_local() {
    with_pkg_lock _pkg_install_local_impl "$@"
}

_pkg_install_local_impl() {
    local pkg_path="$1"
    case "$PKG_MANAGER" in
        apt) sudo apt -o DPkg::Lock::Timeout="$APT_LOCK_TIMEOUT" install -y "$pkg_path" ;;
        dnf) sudo dnf install -y "$pkg_path" ;;
        pacman) sudo pacman -U --noconfirm "$pkg_path" ;;
        zypper) sudo zypper install -y --allow-unsigned-rpm "$pkg_path" ;;
        *) echo "Unsupported package manager: $PKG_MANAGER" >&2; return 1 ;;
    esac
}

### Map package names across distros
### Usage: pkg_name "apt_name" -> returns distro-appropriate name
### Some packages have different names on different distros
pkg_name() {
    local apt_name="$1"
    case "$PKG_MANAGER" in
        apt) echo "$apt_name" ;;
        dnf)
            case "$apt_name" in
                build-essential) echo "gcc gcc-c++ make" ;;
                libinput-dev) echo "libinput-devel" ;;
                ncdu) echo "ncdu" ;;
                ninja-build) echo "ninja-build" ;;
                nvtop) echo "nvtop" ;;
                net-tools) echo "net-tools" ;;
                openssh-server) echo "openssh-server" ;;
                p7zip-full) echo "p7zip p7zip-plugins" ;;
                python3-dev) echo "python3-devel" ;;
                gnome-shell-extension-manager) echo "gnome-extensions-app" ;;
                *) echo "$apt_name" ;;
            esac ;;
        pacman)
            case "$apt_name" in
                build-essential) echo "base-devel" ;;
                gh) echo "github-cli" ;;
                libinput-dev) echo "libinput" ;;
                ncdu) echo "ncdu" ;;
                ninja-build) echo "ninja" ;;
                nvtop) echo "nvtop" ;;
                net-tools) echo "net-tools" ;;
                openssh-server) echo "openssh" ;;
                p7zip-full) echo "p7zip" ;;
                python3-dev) echo "python" ;;
                gnome-shell-extension-manager) echo "extension-manager" ;;
                gnome-tweaks) echo "gnome-tweaks" ;;
                vlc) echo "vlc" ;;
                *) echo "$apt_name" ;;
            esac ;;
        zypper)
            case "$apt_name" in
                build-essential) echo "gcc gcc-c++ make" ;;
                p7zip-full) echo "p7zip" ;;
                python3-dev) echo "python3-devel" ;;
                *) echo "$apt_name" ;;
            esac ;;
        *) echo "$apt_name" ;;
    esac
}

###############################################################################
### GitHub Release Architecture Mapping
###############################################################################

# Maps tool name to its GitHub release architecture suffix
# Usage: arch_suffix=$(get_release_arch "bat")
get_release_arch() {
    local tool="$1"
    case "$tool" in
        # Standard Rust musl/gnu builds (most tools)
        bat|fd|ripgrep|delta|eza|bottom|zoxide)
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
        # ShellCheck (the linter) uses linux.arch format
        shellcheck)
            case "$ARCH" in
                x86_64) echo "linux.x86_64" ;;
                arm64)  echo "linux.aarch64" ;;
            esac ;;
        # fastfetch uses non-standard naming (linux-amd64 instead of x86_64)
        fastfetch)
            case "$ARCH" in
                x86_64) echo "linux-amd64" ;;
                arm64)  echo "linux-aarch64" ;;
            esac ;;
        # tealdeer releases raw binaries with musl suffix
        tealdeer)
            case "$ARCH" in
                x86_64) echo "linux-x86_64-musl" ;;
                arm64)  echo "linux-aarch64-musl" ;;
            esac ;;
        # neovim uses simple arch naming
        neovim)
            case "$ARCH" in
                x86_64) echo "linux-x86_64" ;;
                arm64)  echo "linux-arm64" ;;
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
# Usage: install_github_binary "owner/repo" "tool_name" [binary_name] [strip_components] [type]
#   - owner/repo: GitHub repository (e.g., "sharkdp/bat")
#   - tool_name: Tool name for arch lookup and tarball naming
#   - binary_name: Name of binary inside archive (defaults to tool_name)
#   - strip_components: tar --strip-components value (default: 1)
#       Use 0 for flat archives where the binary is at the archive root
#       Use 1 for archives with a single top-level directory (most common)
#   - type: "auto" (default) tries archives, "raw" downloads raw binary (e.g., tealdeer)
install_github_binary() {
    local repo="$1"
    local tool="$2"
    local binary="${3:-$tool}"
    local strip="${4:-1}"
    local dl_type="${5:-auto}"

    local version arch_suffix tmpdir archive_url

    version=$(github_latest_version "$repo") || return 1
    arch_suffix=$(get_release_arch "$tool") || return 1

    tmpdir=$(mktemp -d)

    # Cleanup function - called by trap or explicitly on success
    _cleanup_tmpdir() { rm -rf "$tmpdir"; }
    trap _cleanup_tmpdir EXIT TERM INT

    local base_url="https://github.com/$repo/releases/download"

    # Handle raw binary downloads (e.g., tealdeer releases raw executables, not archives)
    if [[ "$dl_type" == "raw" ]]; then
        local raw_patterns=(
            # tealdeer style: tealdeer-linux-x86_64-musl
            "$base_url/v${version}/${tool}-${arch_suffix}"
            # Alternative without v prefix
            "$base_url/${version}/${tool}-${arch_suffix}"
        )

        local raw_url=""
        for pattern in "${raw_patterns[@]}"; do
            if curl -fsSL --head --connect-timeout 5 --max-time 10 "$pattern" &>/dev/null; then
                raw_url="$pattern"
                break
            fi
        done

        if [[ -z "$raw_url" ]]; then
            echo "Could not find raw binary URL for $tool v$version" >&2
            _cleanup_tmpdir
            trap - EXIT TERM INT
            return 1
        fi

        mkdir -p "$HOME/.local/bin"
        if ! curl -fL --connect-timeout 30 --max-time 600 --progress-bar \
                -o "$HOME/.local/bin/$binary" "$raw_url"; then
            _cleanup_tmpdir
            trap - EXIT TERM INT
            return 1
        fi
        chmod +x "$HOME/.local/bin/$binary"

        _cleanup_tmpdir
        trap - EXIT TERM INT
        return 0
    fi

    # Archive download: try different naming conventions
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
        # shellcheck style: shellcheck-v0.10.0.linux.x86_64.tar.xz
        "$base_url/v${version}/${tool}-v${version}.${arch_suffix}.tar.xz"
    )

    archive_url=""
    for pattern in "${patterns[@]}"; do
        # Use short timeout for HEAD requests to fail fast on non-existent URLs
        if curl -fsSL --head --connect-timeout 5 --max-time 10 "$pattern" &>/dev/null; then
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
    if ! curl -fL --connect-timeout 30 --max-time 600 --progress-bar \
            -o "$archive_file" "$archive_url"; then
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
        *.tar.xz)
            tar xJf "$archive_file" -C "$tmpdir" --strip-components="$strip" && extract_ok=true
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

# When running standalone (not orchestrated), set sensible defaults
# Only prompts for sudo if the calling script requires it (@requires: sudo)
standalone_init() {
    if [[ "${ORCHESTRATED:-}" == "true" ]]; then
        return 0
    fi
    
    # Running standalone - set sensible defaults without prompts
    : "${DRY_RUN:=false}"
    : "${HEADLESS:=N}"  # Default to non-headless, no prompt
    
    # Determine the calling script (to check its metadata)
    local caller_script="${BASH_SOURCE[1]}"
    
    # Only prompt for sudo if this specific script requires it
    if [[ -z "${HAS_SUDO:-}" ]]; then
        if sudo -n true 2>/dev/null || [[ $EUID -eq 0 ]]; then
            HAS_SUDO=true
        elif script_requires_sudo "$caller_script"; then
            # This script needs sudo - prompt for it
            if prompt_yn "Authenticate with sudo? [Y/n]" "Y"; then
                if sudo -v; then
                    HAS_SUDO=true
                else
                    HAS_SUDO=false
                fi
            else
                HAS_SUDO=false
            fi
        else
            # Script doesn't require sudo - skip silently
            HAS_SUDO=false
        fi
    fi
    
    # Read git config defaults silently (no prompts)
    if [[ -z "${GIT_NAME:-}" ]]; then
        GIT_NAME=$(_read_config_value "git_name") || GIT_NAME="Peter Sharpe"
    fi
    if [[ -z "${GIT_EMAIL:-}" ]]; then
        GIT_EMAIL=$(_read_config_value "git_email") || GIT_EMAIL="peterdsharpe@gmail.com"
    fi
    
    # Export for any child processes
    export DRY_RUN HEADLESS HAS_SUDO GIT_NAME GIT_EMAIL
}
