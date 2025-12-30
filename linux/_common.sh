#!/bin/bash
# Shared utilities for peter-terminal-utils install scripts
# This file is sourced by both the orchestrator (setup.sh) and individual install scripts

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

# State for grouped commands
STEP_FAILED=false
STEP_MSG=""

# Track if any step in the entire script failed
SCRIPT_FAILED=false

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
    return $_EXEC_EXIT
}

### Core helper: print error details from last _exec call
_print_error() {
    local cmd_desc="$1"
    echo -e "  ${RED}Failed:${NC} $cmd_desc (exit code: $_EXEC_EXIT)"
    if [ -n "$_EXEC_OUT" ]; then
        echo -e "  ${RED}Stdout:${NC}"
        echo "$_EXEC_OUT" | sed 's/^/    /'
    fi
    if [ -n "$_EXEC_ERR" ]; then
        echo -e "  ${RED}Stderr:${NC}"
        echo "$_EXEC_ERR" | sed 's/^/    /'
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
        SCRIPT_FAILED=true
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
        SCRIPT_FAILED=true
    else
        echo -e "${GREEN}✓${NC} $STEP_MSG"
    fi
}

###############################################################################
### Helper Functions
###############################################################################

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
### Standalone Script Support
###############################################################################

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
    
    if [[ -z "${GIT_NAME:-}" ]]; then
        GIT_NAME=$(prompt_input "Git user name" "Peter Sharpe")
    fi
    
    if [[ -z "${GIT_EMAIL:-}" ]]; then
        GIT_EMAIL=$(prompt_input "Git email" "peterdsharpe@gmail.com")
    fi
    
    # Export for any child processes
    export DRY_RUN HEADLESS HAS_SUDO GIT_NAME GIT_EMAIL
}

