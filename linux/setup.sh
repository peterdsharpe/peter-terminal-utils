#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

###############################################################################
### Script Setup
###############################################################################

# Get script directory (where dotfiles are stored)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Architecture detection for binary downloads
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

### Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

### Logging helpers
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
    
    if [[ "$DRY_RUN" == true ]]; then
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
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}ℹ${NC} [DRY RUN] $STEP_MSG"
    else
        printf "${CYAN}▶${NC} %s " "$STEP_MSG"
    fi
}

### Run a command within a group (silent on success, shows error on failure)
run() {
    if [[ "$DRY_RUN" == true ]]; then
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
    if [[ "$DRY_RUN" == true ]]; then
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
    if [[ "$DRY_RUN" == true ]]; then
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

### Install a command if not already present
### Optional 4th param "sudo" skips if HAS_SUDO=false
ensure_command() {
    local name="$1"
    local cmd="$2"
    local install_func="$3"
    local needs_sudo="${4:-}"
    
    if [[ "$needs_sudo" == "sudo" && "$HAS_SUDO" == false ]]; then
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
    if [[ "$HAS_SUDO" == true ]]; then
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


### Interactive configuration questions
echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                     Peter Sharpe's Linux Setup Script                         ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if prompt_yn "Dry run (preview changes without making them)? [y/N]" "N"; then
    DRY_RUN=true
else
    DRY_RUN=false
fi

if prompt_yn "Headless mode (skip GUI packages)? [y/N]" "N"; then
    HEADLESS="Y"
else
    HEADLESS="N"
fi

if prompt_yn "Install snap applications? [Y/n]" "Y"; then
    INSTALL_SNAPS="Y"
else
    INSTALL_SNAPS="N"
fi

GIT_NAME=$(prompt_input "Git user name" "Peter Sharpe")
GIT_EMAIL=$(prompt_input "Git email" "peterdsharpe@gmail.com")

### Detect and configure sudo access
if [[ $EUID -eq 0 ]]; then
    # Already running as root
    HAS_SUDO=true
    print_info "Running as root"
elif sudo -n true 2>/dev/null; then
    # Sudo available (cached credentials or NOPASSWD configured)
    HAS_SUDO=true
    print_info "Sudo access available"
    # Start keepalive to prevent credential timeout mid-script
    (while true; do sudo -v; sleep 60; done) &
    SUDO_KEEPALIVE_PID=$!
    trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
else
    # Not elevated - ask user what they want to do
    echo ""
    print_warning "Not running with sudo privileges."
    echo "    1) Authenticate with sudo (full installation)"
    echo "    2) Proceed without sudo (limited functionality)"
    echo ""
    if prompt_yn "Authenticate with sudo? [Y/n]" "Y"; then
        # Attempt sudo authentication
        echo ""
        if sudo -v; then
            HAS_SUDO=true
            print_success "Sudo authentication successful"
            # Keep sudo credentials alive in background
            (while true; do sudo -v; sleep 60; done) &
            SUDO_KEEPALIVE_PID=$!
            trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
        else
            print_error "Sudo authentication failed"
            if prompt_yn "Continue without sudo (limited functionality)? [Y/n]" "Y"; then
                HAS_SUDO=false
            else
                exit 1
            fi
        fi
    else
        HAS_SUDO=false
        print_info "Proceeding without sudo"
    fi
fi

echo ""
print_info "Configuration: HEADLESS=$HEADLESS, INSTALL_SNAPS=$INSTALL_SNAPS, DRY_RUN=$DRY_RUN, HAS_SUDO=$HAS_SUDO"
print_info "Git: $GIT_NAME <$GIT_EMAIL>"

###############################################################################
### System Packages (apt-get)
###############################################################################

print_header "System Packages"

install_system_packages() {
    # Core packages (always installed)
    local packages=(
        zsh git vim neovim tmux htop curl wget
        build-essential
        ripgrep fd-find fzf bat eza tree ncdu jq cloc
        unzip zip
        net-tools openssh-server
        zoxide
        git-lfs            # Large file storage for git
        pandoc             # Universal document converter
        nvtop              # GPU monitoring (for ML/CUDA work)
        rclone             # Cloud storage sync
    )

    # GUI packages (only if not headless)
    if [[ "$HEADLESS" == "N" ]]; then
        packages+=(
            nemo
            gnome-shell-extension-manager gnome-tweaks
            vlc dconf-editor
        )
    fi

    step_start "Installing system packages"
    run sudo apt-get update -qq
    run sudo apt-get upgrade -yq
    run sudo apt-get install -yq "${packages[@]}"
    step_end
}
require_sudo "System packages" install_system_packages

### Ensure SSH service is enabled and starts at boot
configure_ssh_service() {
    step "Enabling SSH service (starts at boot)" sudo systemctl enable --now ssh
    
    # If ufw firewall is active, allow SSH connections
    if sudo ufw status 2>/dev/null | grep -q "active"; then
        step "Allowing SSH through firewall" sudo ufw allow ssh
    fi
}
require_sudo "SSH service" configure_ssh_service

###############################################################################
### Manual CLI Tool Installs
###############################################################################

### Helper: Get latest version from GitHub releases (uses redirect, not API - avoids rate limits)
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

print_header "CLI Tools"

### Install GitHub CLI (gh) - can install without sudo using prebuilt binary
install_github_cli() {
    if [[ "$HAS_SUDO" == true ]]; then
        # Install via apt repository (preferred for system-wide install)
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || return 1
        sudo apt-get update -qq || return 1
        sudo apt-get install -yq gh
    else
        # Install prebuilt binary to ~/.local/bin
        local version gh_arch
        version=$(github_latest_version "cli/cli") || return 1
        case "$ARCH" in
            x86_64) gh_arch="amd64" ;;
            arm64) gh_arch="arm64" ;;
        esac
        curl -fSL -o gh.tar.gz "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${gh_arch}.tar.gz" || return 1
        tar xf gh.tar.gz || return 1
        install -m 755 "gh_${version}_linux_${gh_arch}/bin/gh" "$HOME/.local/bin/gh" || return 1
        rm -rf gh.tar.gz "gh_${version}_linux_${gh_arch}"
    fi
}
ensure_command "GitHub CLI" gh install_github_cli

### Install lazygit (can install without sudo to ~/.local/bin)
install_lazygit() {
    local version lazygit_arch
    version=$(github_latest_version "jesseduffield/lazygit") || return 1
    case "$ARCH" in
        x86_64) lazygit_arch="x86_64" ;;
        arm64) lazygit_arch="arm64" ;;
    esac
    curl -fSL -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${lazygit_arch}.tar.gz" || return 1
    tar xf lazygit.tar.gz lazygit || return 1
    if [[ "$HAS_SUDO" == true ]]; then
        sudo install lazygit /usr/local/bin || return 1
    else
        install -m 755 lazygit "$HOME/.local/bin/lazygit" || return 1
    fi
    rm lazygit lazygit.tar.gz
}
ensure_command "lazygit" lazygit install_lazygit

### Install fzf (fuzzy finder) - can install without sudo via git
install_fzf() {
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || return 1
    "$HOME/.fzf/install" --bin || return 1
    install -m 755 "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
}
ensure_command "fzf" fzf install_fzf

### Install fd (find alternative) - can install without sudo
install_fd() {
    local version fd_arch
    version=$(github_latest_version "sharkdp/fd") || return 1
    case "$ARCH" in
        x86_64) fd_arch="x86_64-unknown-linux-musl" ;;
        arm64) fd_arch="aarch64-unknown-linux-gnu" ;;
    esac
    curl -fSL -o fd.tar.gz "https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-${fd_arch}.tar.gz" || return 1
    tar xf fd.tar.gz || return 1
    install -m 755 "fd-v${version}-${fd_arch}/fd" "$HOME/.local/bin/fd" || return 1
    rm -rf fd.tar.gz "fd-v${version}-${fd_arch}"
}
ensure_command "fd" fd install_fd

### Install bat (cat alternative) - can install without sudo
install_bat() {
    local version bat_arch
    version=$(github_latest_version "sharkdp/bat") || return 1
    case "$ARCH" in
        x86_64) bat_arch="x86_64-unknown-linux-musl" ;;
        arm64) bat_arch="aarch64-unknown-linux-gnu" ;;
    esac
    curl -fSL -o bat.tar.gz "https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-${bat_arch}.tar.gz" || return 1
    tar xf bat.tar.gz || return 1
    install -m 755 "bat-v${version}-${bat_arch}/bat" "$HOME/.local/bin/bat" || return 1
    rm -rf bat.tar.gz "bat-v${version}-${bat_arch}"
}
ensure_command "bat" bat install_bat

### Install eza (ls alternative) - can install without sudo
install_eza() {
    local version eza_arch
    version=$(github_latest_version "eza-community/eza") || return 1
    case "$ARCH" in
        x86_64) eza_arch="x86_64-unknown-linux-musl" ;;
        arm64) eza_arch="aarch64-unknown-linux-gnu" ;;
    esac
    curl -fSL -o eza.tar.gz "https://github.com/eza-community/eza/releases/download/v${version}/eza_${eza_arch}.tar.gz" || return 1
    tar xf eza.tar.gz || return 1
    install -m 755 eza "$HOME/.local/bin/eza" || return 1
    rm -f eza.tar.gz eza
}
ensure_command "eza" eza install_eza

### Install neovim - can install without sudo
install_neovim() {
    local version nvim_arch nvim_dir
    version=$(github_latest_version "neovim/neovim") || return 1
    case "$ARCH" in
        x86_64) nvim_arch="x86_64"; nvim_dir="nvim-linux-x86_64" ;;
        arm64) nvim_arch="arm64"; nvim_dir="nvim-linux-arm64" ;;
    esac
    mkdir -p "$HOME/local" || return 1
    curl -fSL -o nvim.tar.gz "https://github.com/neovim/neovim/releases/download/v${version}/nvim-linux-${nvim_arch}.tar.gz" || return 1
    tar xf nvim.tar.gz || return 1
    rm -rf "$HOME/local/nvim" || return 1
    mv "$nvim_dir" "$HOME/local/nvim" || return 1
    ln -sf "$HOME/local/nvim/bin/nvim" "$HOME/.local/bin/nvim" || return 1
    rm -f nvim.tar.gz
}
ensure_command "neovim" nvim install_neovim

### Install zoxide (smarter cd) - uses official install script
install_zoxide() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}
ensure_command "zoxide" zoxide install_zoxide

### Install delta (better git diffs) - can install without sudo
install_delta() {
    local version delta_arch
    version=$(github_latest_version "dandavison/delta") || return 1
    case "$ARCH" in
        x86_64) delta_arch="x86_64-unknown-linux-musl" ;;
        arm64) delta_arch="aarch64-unknown-linux-gnu" ;;
    esac
    curl -fSL -o delta.tar.gz "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-${delta_arch}.tar.gz" || return 1
    tar xf delta.tar.gz || return 1
    install -m 755 "delta-${version}-${delta_arch}/delta" "$HOME/.local/bin/delta" || return 1
    rm -rf delta.tar.gz "delta-${version}-${delta_arch}"
}
ensure_command "delta" delta install_delta

### Install bottom (btm) - modern system monitor with GPU support
install_bottom() {
    local version btm_arch tmpdir
    version=$(github_latest_version "ClementTsang/bottom") || return 1
    case "$ARCH" in
        x86_64) btm_arch="x86_64-unknown-linux-musl" ;;
        arm64) btm_arch="aarch64-unknown-linux-gnu" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/bottom.tar.gz" "https://github.com/ClementTsang/bottom/releases/download/${version}/bottom_${btm_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/bottom.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    install -m 755 "$tmpdir/btm" "$HOME/.local/bin/btm" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}
ensure_command "bottom" btm install_bottom

### Install btop - visually polished system monitor with mouse support
install_btop() {
    local version btop_arch tmpdir
    version=$(github_latest_version "aristocratos/btop") || return 1
    case "$ARCH" in
        x86_64) btop_arch="x86_64-linux-musl" ;;
        arm64) btop_arch="aarch64-linux-musl" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/btop.tbz" "https://github.com/aristocratos/btop/releases/download/v${version}/btop-${btop_arch}.tbz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/btop.tbz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    install -m 755 "$tmpdir/btop/bin/btop" "$HOME/.local/bin/btop" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}
ensure_command "btop" btop install_btop

### Install Docker
install_docker() {
    curl -fsSL https://get.docker.com | sh || return 1
    sudo usermod -aG docker "$USER"
}
ensure_command "Docker" docker install_docker sudo
# Show warning if user not yet in docker group (requires logout/login to take effect)
if [[ "$HAS_SUDO" == true ]] && ! groups | grep -q docker; then
    print_warning "Log out and back in to use docker without sudo"
fi

### Install zsh (build from source if no sudo)
install_zsh_from_source() {
    # Check for required build tools
    if ! command -v gcc &>/dev/null || ! command -v make &>/dev/null; then
        echo "Missing build tools (gcc, make) - cannot compile zsh from source" >&2
        return 1
    fi
    
    # Create install directory
    mkdir -p "$HOME/local" || return 1
    
    # Fetch latest version from zsh.org
    local version
    version=$(curl -s https://www.zsh.org/pub/ | grep -oP 'zsh-\K[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -V | tail -1) || return 1
    [ -n "$version" ] || { echo "Could not determine latest zsh version" >&2; return 1; }
    
    # Download and extract
    curl -Lo zsh.tar.xz "https://www.zsh.org/pub/zsh-${version}.tar.xz" || return 1
    tar xf zsh.tar.xz || return 1
    cd "zsh-${version}" || return 1
    
    # Configure, build, install to ~/local
    ./configure --prefix="$HOME/local" --without-tcsetpgrp || return 1
    make -j"$(nproc)" || return 1
    make install || return 1
    
    # Cleanup
    cd ..
    rm -rf "zsh-${version}" zsh.tar.xz
}

if command -v zsh &>/dev/null || [ -x "$HOME/local/bin/zsh" ]; then
    print_skip "zsh already installed"
elif [[ "$HAS_SUDO" == true ]]; then
    # zsh should already be installed via apt in System Packages section
    print_warning "zsh not found - should have been installed via apt"
else
    # Build from source for sudo-less install
    if command -v gcc &>/dev/null && command -v make &>/dev/null; then
        step "Building zsh from source (no sudo)" install_zsh_from_source
    else
        print_skip "zsh (requires build tools: gcc, make)"
    fi
fi

# Ensure ~/local/bin is in PATH for this script session (needed for oh-my-zsh to find zsh)
if [ -d "$HOME/local/bin" ] && [[ ":$PATH:" != *":$HOME/local/bin:"* ]]; then
    export PATH="$HOME/local/bin:$PATH"
fi

### Add ~/local/bin to .bashrc PATH (for sudo-less installs to be discoverable)
add_local_to_bashrc_path() {
    local bashrc="$HOME/.bashrc"
    local path_line='export PATH="$HOME/local/bin:$PATH"'
    if [ -f "$bashrc" ] && ! grep -qF 'HOME/local/bin' "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# Added by peter-terminal-utils setup - user-local binaries" >> "$bashrc"
        echo "$path_line" >> "$bashrc"
    fi
}
if [[ "$HAS_SUDO" == false ]] && [ -d "$HOME/local/bin" ]; then
    step "Adding ~/local/bin to .bashrc PATH" add_local_to_bashrc_path
fi

###############################################################################
### Fonts
###############################################################################

print_header "Fonts"

step "Creating fonts directory" mkdir -p ~/.local/share/fonts

### Install Fira Code Nerd Font (for terminal icons)
install_firacode() {
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip || return 1
    unzip -o FiraCode.zip -d ~/.local/share/fonts || return 1
    rm FiraCode.zip
}
if ! fc-list | grep -i "FiraCode Nerd Font" > /dev/null; then
    step "Installing Fira Code Nerd Font" install_firacode
else
    print_skip "Fira Code Nerd Font already installed"
fi

### Install Symbols Nerd Font (fallback for missing glyphs)
install_symbols_font() {
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz || return 1
    tar -xf NerdFontsSymbolsOnly.tar.xz -C ~/.local/share/fonts || return 1
    rm NerdFontsSymbolsOnly.tar.xz
}
if ! fc-list | grep -i "Symbols Nerd Font" > /dev/null; then
    step "Installing Symbols Nerd Font" install_symbols_font
else
    print_skip "Symbols Nerd Font already installed"
fi

step "Rebuilding font cache" fc-cache -f

### Configure fontconfig to use Symbols Nerd Font as fallback
configure_fontconfig() {
    mkdir -p ~/.config/fontconfig || return 1
    cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any"><string>FiraCode Nerd Font</string></test>
    <edit name="family" mode="append" binding="weak">
      <string>Symbols Nerd Font</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" qual="any"><string>FiraCode Nerd Font Mono</string></test>
    <edit name="family" mode="append" binding="weak">
      <string>Symbols Nerd Font Mono</string>
    </edit>
  </match>
</fontconfig>
EOF
}
step "Configuring fontconfig fallback" configure_fontconfig

### GNOME settings (only if not headless)
if [[ "$HEADLESS" == "N" ]]; then
    # Set GNOME Terminal font (only if GNOME Terminal is installed)
    if gsettings list-schemas | grep -q "org.gnome.Terminal" 2>/dev/null; then
        configure_gnome_terminal() {
            local profile
            profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'") || return 1
            [ -n "$profile" ] || { echo "No GNOME Terminal profile found" >&2; return 1; }
            gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" font 'FiraCode Nerd Font Mono 11' || return 1
            gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" use-system-font false
        }
        step "Configuring GNOME Terminal font" configure_gnome_terminal
    else
        print_skip "Skipped configuring GNOME Terminal font (GNOME Terminal not installed)"
    fi

    # Individual settings - single commands
    step "Disabling touchpad tap-and-drag" gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
    step "Disabling GNOME animations" gsettings set org.gnome.desktop.interface enable-animations false

    # Keyboard repeat (grouped - related settings)
    step_start "Configuring faster keyboard repeat"
    run gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
    run gsettings set org.gnome.desktop.peripherals.keyboard delay 200
    step_end

    step "Disabling hot corners" gsettings set org.gnome.desktop.interface enable-hot-corners false
    step "Enabling locate pointer with Ctrl" gsettings set org.gnome.desktop.interface locate-pointer true
    step "Enabling battery percentage display" gsettings set org.gnome.desktop.interface show-battery-percentage true
    step "Enabling weekday in clock" gsettings set org.gnome.desktop.interface clock-show-weekday true
    step "Enabling tap to click" gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    step "Enabling two-finger right click" gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
    step "Enabling center new windows" gsettings set org.gnome.mutter center-new-windows true
    step "Setting dark theme" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    step "Setting Firefox as default browser" xdg-settings set default-web-browser firefox_firefox.desktop
    step "Setting Nemo as default file manager" xdg-mime default nemo.desktop inode/directory

    # Nemo file manager settings (grouped)
    step_start "Configuring Nemo file manager"
    run gsettings set org.nemo.preferences show-hidden-files true
    run gsettings set org.nemo.preferences default-folder-viewer 'list-view'
    run gsettings set org.nemo.preferences sort-directories-first true
    step_end

    # Nautilus file manager settings (only if installed)
    if command -v nautilus &> /dev/null; then
        step_start "Configuring Nautilus file manager"
        run gsettings set org.gnome.nautilus.preferences show-hidden-files true
        run gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
        step_end
    fi
fi

###############################################################################
### SSH Setup
###############################################################################

print_header "SSH Setup"

generate_ssh_key() {
    mkdir -p "$HOME/.ssh" || return 1
    chmod 700 "$HOME/.ssh" || return 1
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
}
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    step "Generating SSH key pair" generate_ssh_key
else
    print_skip "SSH key already exists"
fi

###############################################################################
### Development Tools
###############################################################################

print_header "Development Tools"

### Create ~/.local/bin early (needed for user-local tool installs)
step "Creating ~/.local/bin directory" mkdir -p "$HOME/.local/bin"

### Install uv (Python)
install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}
ensure_command "uv" uv install_uv

### Install Python tools via uv
step_start "Installing Python tools"
run ~/.local/bin/uv tool install ruff        # Fast linter/formatter
run ~/.local/bin/uv tool install ty          # Type checker
run ~/.local/bin/uv tool install turm        # TUI for Slurm job management
run ~/.local/bin/uv tool install httpie      # Better HTTP client (http/https commands)
run ~/.local/bin/uv tool install pre-commit  # Git hooks for code quality
run ~/.local/bin/uv tool install yt-dlp      # Video downloader
run ~/.local/bin/uv tool install rich-cli    # Pretty terminal output (rich command)
run ~/.local/bin/uv tool install docling     # PDF to text/markdown for LLM input
run ~/.local/bin/uv tool install jupyterlab  # Jupyter notebooks
run ~/.local/bin/uv tool install pytest      # Testing framework
run ~/.local/bin/uv tool upgrade --all       # Upgrade all tools to latest
step_end

### Install Rust
install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}
ensure_command "Rust" rustup install_rust

### Install Cursor CLI
install_cursor() {
    curl -fsSL https://cursor.com/install | bash
}
ensure_command "Cursor CLI" cursor-agent install_cursor

### Install TeX Live (full distribution - warning: 7+GB, may take 30+ minutes)
### See: https://www.tug.org/texlive/quickinstall.html
install_texlive() {
    local tmpdir year arch_dir texlive_bin
    tmpdir=$(mktemp -d) || return 1
    cd "$tmpdir" || return 1
    
    # Download installer
    curl -L -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz || { cd /; rm -rf "$tmpdir"; return 1; }
    zcat < install-tl-unx.tar.gz | tar xf - || { cd /; rm -rf "$tmpdir"; return 1; }
    cd install-tl-2* || { cd /; rm -rf "$tmpdir"; return 1; }
    
    # Install non-interactively (full scheme by default)
    print_warning "TeX Live installation may take 30+ minutes..."
    sudo perl ./install-tl --no-interaction || { cd /; rm -rf "$tmpdir"; return 1; }
    
    # Cleanup
    cd /
    rm -rf "$tmpdir"
    
    # Determine install path and add to shell profiles
    year=$(ls /usr/local/texlive/ 2>/dev/null | grep -E '^[0-9]{4}$' | sort -n | tail -1)
    if [ -n "$year" ]; then
        case "$ARCH" in
            x86_64) arch_dir="x86_64-linux" ;;
            arm64) arch_dir="aarch64-linux" ;;
        esac
        texlive_bin="/usr/local/texlive/${year}/bin/${arch_dir}"
        if [ -d "$texlive_bin" ]; then
            # Add to .profile for bash login shells
            if ! grep -q "texlive" "$HOME/.profile" 2>/dev/null; then
                echo "" >> "$HOME/.profile"
                echo "# TeX Live" >> "$HOME/.profile"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.profile"
            fi
            # Add to .zprofile for zsh login shells (zsh doesn't source .profile)
            if ! grep -q "texlive" "$HOME/.zprofile" 2>/dev/null; then
                echo "" >> "$HOME/.zprofile"
                echo "# TeX Live" >> "$HOME/.zprofile"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.zprofile"
            fi
        fi
    fi
}
ensure_command "TeX Live" pdflatex install_texlive sudo

###############################################################################
### Shell Setup
###############################################################################

print_header "Shell Setup"

### Install Oh My Zsh (non-interactive, skip if already installed)
install_ohmyzsh() {
    # Remove incomplete installation if present
    rm -rf "$HOME/.oh-my-zsh"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}
# Check for actual oh-my-zsh.sh file, not just directory (catches incomplete installs)
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    step "Installing Oh My Zsh" install_ohmyzsh
else
    print_skip "Oh My Zsh already installed"
fi

### Install Oh My Zsh plugins (skip if already cloned)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    step "Installing zsh-syntax-highlighting plugin" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    print_skip "zsh-syntax-highlighting already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    step "Installing zsh-autosuggestions plugin" git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    print_skip "zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
    step "Installing zsh-history-substring-search plugin" git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
else
    print_skip "zsh-history-substring-search already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    step "Installing zsh-autocomplete plugin" git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
else
    print_skip "zsh-autocomplete already installed"
fi

### Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    step "Installing Powerlevel10k theme" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    print_skip "Powerlevel10k already installed"
fi

### Symlink .zshrc from dotfiles
setup_zshrc() {
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$SCRIPT_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
}
step "Symlinking .zshrc" setup_zshrc

### Symlink neovim config from dotfiles
setup_nvim_config() {
    mkdir -p "$HOME/.config/nvim" || return 1
    if [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -L "$HOME/.config/nvim/init.vim" ]; then
        mv "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$SCRIPT_DIR/dotfiles/init.vim" "$HOME/.config/nvim/init.vim"
}
step "Symlinking neovim config" setup_nvim_config

### Set up global ipy Python environment
print_step "Syncing ipy Python environment"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}ℹ${NC} [DRY RUN] uv sync --project $SCRIPT_DIR/../ipy"
else
    uv sync --project "$SCRIPT_DIR/../ipy" && print_success "Synced ipy Python environment" || { print_error "Failed to sync ipy Python environment"; SCRIPT_FAILED=true; }
fi
step "Symlinking ipy command" ln -sf "$SCRIPT_DIR/../ipy/IPy.sh" "$HOME/.local/bin/ipy"

### Copy Powerlevel10k config if it doesn't exist (or prompt to overwrite)
if [ ! -f "$HOME/.p10k.zsh" ]; then
    step "Copying Powerlevel10k config" cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
else
    if prompt_yn "Powerlevel10k config already exists. Overwrite with saved config? [y/N]" "N"; then
        step "Overwriting Powerlevel10k config" cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
    else
        print_skip "Keeping existing Powerlevel10k config"
    fi
fi

###############################################################################
### Snap Applications
###############################################################################

print_header "Snap Applications"

install_snap_apps() {
    step_start "Installing snap applications"
    run sudo snap install obsidian --classic
    run sudo snap install zotero-snap
    run sudo snap install code --classic
    run sudo snap install firefox
    run sudo snap install inkscape
    run sudo snap install libreoffice
    run sudo snap install steam
    step_end
}

### Install Signal Desktop via official apt repository (preferred over Snap)
install_signal() {
    # Official Signal apt repository - https://signal.org/download/linux/
    curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null || return 1
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee /etc/apt/sources.list.d/signal-xenial.list > /dev/null || return 1
    sudo apt-get update -qq || return 1
    sudo apt-get install -yq signal-desktop
}
ensure_command "Signal Desktop" signal-desktop install_signal sudo

if [[ "$INSTALL_SNAPS" != "Y" ]]; then
    print_skip "Snap installations disabled"
else
    require_sudo "Snap applications" install_snap_apps
fi

###############################################################################
### Git Configuration
###############################################################################

print_header "Git Configuration"

step_start "Configuring git"
run git config --global user.name "$GIT_NAME"
run git config --global user.email "$GIT_EMAIL"
run git config --global init.defaultBranch main
run git config --global pull.rebase false
run git config --global core.editor "nvim"
run git config --global push.autoSetupRemote true
run git config --global fetch.prune true
# Aliases
run git config --global alias.st status
run git config --global alias.co checkout
run git config --global alias.br branch
run git config --global alias.lg "log --oneline --graph --decorate"
run git config --global alias.amend "commit --amend --no-edit"
run git config --global alias.last "log -1 HEAD --stat"
# Delta integration for better diffs
run git config --global core.pager delta
run git config --global interactive.diffFilter 'delta --color-only'
run git config --global delta.navigate true
run git config --global delta.side-by-side true
# Better merge/rebase defaults
run git config --global merge.conflictstyle diff3
run git config --global rebase.autoStash true
# Initialize git-lfs (only needed once per user)
run git lfs install
step_end

###############################################################################
### Final Steps
###############################################################################

print_header "Final Steps"

### Install Dash to Panel extension (only if not headless)
if [[ "$HEADLESS" == "N" ]]; then
    if command -v gnome-extensions &> /dev/null; then
        EXTENSION_UUID="dash-to-panel@jderose9.github.com"
        
        install_dash_to_panel() {
            local shell_version download_path
            shell_version=$(gnome-shell --version | grep -oP '\d+' | head -1) || return 1
            download_path=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$EXTENSION_UUID&shell_version=$shell_version" | jq -r '.download_url // empty') || return 1
            [ -n "$download_path" ] || { echo "No download URL found for Dash to Panel extension" >&2; return 1; }
            curl -sL "https://extensions.gnome.org$download_path" -o /tmp/dash-to-panel.zip || return 1
            gnome-extensions install --force /tmp/dash-to-panel.zip || return 1
            rm /tmp/dash-to-panel.zip
        }
        
        if ! gnome-extensions list | grep -q "$EXTENSION_UUID" 2>&1; then
            step "Installing Dash to Panel extension" install_dash_to_panel
        else
            print_skip "Dash to Panel already installed"
        fi

        # Enable extension and load settings
        if gnome-extensions list | grep -q "$EXTENSION_UUID" 2>&1; then
            step "Enabling Dash to Panel" gnome-extensions enable "$EXTENSION_UUID"

            if [ -f "$SCRIPT_DIR/dash-to-panel-settings" ]; then
                step_start "Loading Dash to Panel settings"
                run_stdin "$SCRIPT_DIR/dash-to-panel-settings" dconf load /org/gnome/shell/extensions/dash-to-panel/
                step_end
            fi
        fi
    fi
fi

### Change default shell to zsh (skip if already zsh)
change_default_shell() {
    step "Changing default shell to zsh" sudo chsh -s "$(which zsh)" "$USER"
}
if [ "$SHELL" != "$(which zsh)" ]; then
    require_sudo "Default shell change" change_default_shell
else
    print_skip "Shell is already zsh"
fi

###############################################################################
### Summary
###############################################################################

print_header "Setup Complete!"

echo ""
if [[ "$HAS_SUDO" == false ]]; then
    print_warning "Ran in limited mode (no sudo) - skipped: apt packages, snap apps, shell change"
    echo ""
fi
print_success "All done! Here's what to do next:"
echo ""

# GitHub CLI auth reminder
if command -v gh &> /dev/null; then
    print_info "Authenticate GitHub CLI:"
    echo "    gh auth login"
    echo ""
fi

print_info "Set up VS Code / Cursor to use PeterProfile as the default profile"
echo "    Find at https://gist.github.com/peterdsharpe"
echo ""

if [[ "$HAS_SUDO" == true ]]; then
    print_warning "Log out and back in to use zsh as your default shell"
    echo ""
fi

# Exit with failure if any step failed
if [[ "$SCRIPT_FAILED" == true ]]; then
    print_error "Some steps failed - review output above"
    exit 1
fi
