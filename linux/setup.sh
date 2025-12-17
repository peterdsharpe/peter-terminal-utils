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

### Single command with message - prints ✓ or ✗ when done
step() {
    local msg="$1"; shift
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}ℹ${NC} [DRY RUN] $msg: $*"
        return 0
    fi
    
    local tmp_err
    tmp_err=$(mktemp)
    printf "${CYAN}▶${NC} %s " "$msg"
    if "$@" 2>"$tmp_err"; then
        printf "\r\033[K"
        echo -e "${GREEN}✓${NC} $msg"
    else
        printf "\r\033[K"
        echo -e "${RED}✗${NC} $msg"
        echo -e "  ${RED}Failed:${NC} $*"
        if [ -s "$tmp_err" ]; then
            echo -e "  ${RED}Error:${NC}"
            sed 's/^/    /' "$tmp_err"
        fi
        SCRIPT_FAILED=true
    fi
    rm -f "$tmp_err"
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

### Run a command within a group (silent, tracks failure)
run() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "    ${BLUE}↳${NC} $*"
        return 0
    fi
    local tmp_err
    tmp_err=$(mktemp)
    if ! "$@" 2>"$tmp_err"; then
        # Clear line, print error, then reprint the step indicator
        printf "\r\033[K"
        echo -e "  ${RED}Failed:${NC} $*"
        if [ -s "$tmp_err" ]; then
            echo -e "  ${RED}Error:${NC}"
            sed 's/^/    /' "$tmp_err"
        fi
        printf "${CYAN}▶${NC} %s " "$STEP_MSG"
        STEP_FAILED=true
    fi
    rm -f "$tmp_err"
}

### Run a command with stdin from a file
run_stdin() {
    local input_file="$1"; shift
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "    ${BLUE}↳${NC} $* < $input_file"
        return 0
    fi
    local tmp_err
    tmp_err=$(mktemp)
    if ! "$@" < "$input_file" 2>"$tmp_err"; then
        printf "\r\033[K"
        echo -e "  ${RED}Failed:${NC} $* < $input_file"
        if [ -s "$tmp_err" ]; then
            echo -e "  ${RED}Error:${NC}"
            sed 's/^/    /' "$tmp_err"
        fi
        printf "${CYAN}▶${NC} %s " "$STEP_MSG"
        STEP_FAILED=true
    fi
    rm -f "$tmp_err"
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
ensure_command() {
    local name="$1"
    local cmd="$2"
    local install_func="$3"
    
    if ! command -v "$cmd" &> /dev/null; then
        step "Installing $name" "$install_func"
    else
        print_skip "$name already installed"
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
echo -e "${BOLD}${CYAN}║                         Linux Setup Script                                    ║${NC}"
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

echo ""
print_info "Configuration: HEADLESS=$HEADLESS, INSTALL_SNAPS=$INSTALL_SNAPS, DRY_RUN=$DRY_RUN"
print_info "Git: $GIT_NAME <$GIT_EMAIL>"

### Cache sudo credentials (skip in dry-run mode)
if [[ "$DRY_RUN" == false ]]; then
    step "Caching sudo credentials" sudo -v
    # Keep sudo credentials alive in background during script execution
    (while true; do sudo -v; sleep 60; done) &
    SUDO_KEEPALIVE_PID=$!
    trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
fi

###############################################################################
### System Packages (apt-get)
###############################################################################

print_header "System Packages"

# Core packages (always installed)
PACKAGES=(
    zsh git vim neovim tmux htop curl wget
    build-essential
    ripgrep fd-find fzf bat eza tree ncdu jq
    unzip zip
    net-tools openssh-server
    zoxide
)

# GUI packages (only if not headless)
if [[ "$HEADLESS" == "N" ]]; then
    PACKAGES+=(
        nemo
        gnome-shell-extension-manager gnome-tweaks
        vlc dconf-editor
    )
fi

step_start "Installing system packages"
run sudo apt-get update -qq
run sudo apt-get upgrade -yq
run sudo apt-get install -yq "${PACKAGES[@]}"
step_end

###############################################################################
### Manual CLI Tool Installs
###############################################################################

print_header "CLI Tools"

### Install GitHub CLI (gh)
install_github_cli() {
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || return 1
    sudo apt-get update -qq || return 1
    sudo apt-get install -yq gh
}
ensure_command "GitHub CLI" gh install_github_cli

### Install lazygit
install_lazygit() {
    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') || return 1
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${ARCH}.tar.gz" || return 1
    tar xf lazygit.tar.gz lazygit || return 1
    sudo install lazygit /usr/local/bin || return 1
    rm lazygit lazygit.tar.gz
}
ensure_command "lazygit" lazygit install_lazygit

### Install Docker
install_docker() {
    curl -fsSL https://get.docker.com | sh || return 1
    sudo usermod -aG docker "$USER"
}
ensure_command "Docker" docker install_docker
# Show warning if user not yet in docker group (requires logout/login to take effect)
groups | grep -q docker || print_warning "Log out and back in to use docker without sudo"

###############################################################################
### Fonts
###############################################################################

print_header "Fonts"

step "Creating fonts directory" mkdir -p ~/.local/share/fonts

### Install Fira Code Nerd Font (for terminal icons)
install_firacode() {
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip || return 1
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
    # Set GNOME Terminal font
    configure_gnome_terminal() {
        local profile
        profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'") || return 1
        [ -n "$profile" ] || { echo "No GNOME Terminal profile found" >&2; return 1; }
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" font 'FiraCode Nerd Font Mono 11' || return 1
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" use-system-font false
    }
    step "Configuring GNOME Terminal font" configure_gnome_terminal

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

### Add SSH key to GitHub (requires gh auth)
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    if gh auth status &>/dev/null; then
        if prompt_yn "Add SSH key to GitHub? [y/N]" "N"; then
            step "Adding SSH key to GitHub" gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname)"
        else
            print_skip "SSH key not added to GitHub"
        fi
    else
        print_info "Run 'gh auth login' then 'gh ssh-key add ~/.ssh/id_ed25519.pub' to add your key to GitHub"
    fi
fi

###############################################################################
### Shell Setup
###############################################################################

print_header "Shell Setup"

### Install Oh My Zsh (non-interactive, skip if already installed)
install_ohmyzsh() {
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}
if [ ! -d "$HOME/.oh-my-zsh" ]; then
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

### Set up global ipy Python environment
step "Syncing ipy Python environment" uv sync --project "$SCRIPT_DIR/../ipy"
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
### Development Tools
###############################################################################

print_header "Development Tools"

### Install uv (Python)
install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}
ensure_command "uv" uv install_uv

### Install Python tools via uv
step_start "Installing Python tools (ruff, ty)"
run ~/.local/bin/uv tool install ruff
run ~/.local/bin/uv tool install ty
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

###############################################################################
### Snap Applications
###############################################################################

print_header "Snap Applications"

if [[ "$INSTALL_SNAPS" == "Y" ]]; then
    step_start "Installing snap applications"
    run sudo snap install obsidian --classic
    run sudo snap install signal-desktop
    run sudo snap install zotero-snap
    run sudo snap install code --classic
    step_end
else
    print_skip "Snap installations disabled"
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
run git config --global alias.st status
run git config --global alias.co checkout
run git config --global alias.br branch
run git config --global alias.lg "log --oneline --graph --decorate"
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
if [ "$SHELL" != "$(which zsh)" ]; then
    step "Changing default shell to zsh" sudo chsh -s "$(which zsh)" "$USER"
else
    print_skip "Shell is already zsh"
fi

###############################################################################
### Summary
###############################################################################

print_header "Setup Complete!"

echo ""
print_success "All done! Here's what to do next:"
echo ""

# GitHub CLI auth reminder
if command -v gh &> /dev/null; then
    print_info "Authenticate GitHub CLI:"
    echo "    gh auth login"
    echo ""
fi

# SSH key reminder
if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    print_info "Add your SSH key to GitHub:"
    echo "    https://github.com/settings/ssh/new"
    echo ""
fi

print_info "Set up VS Code / Cursor to use PeterProfile as the default profile"
echo ""

print_warning "Log out and back in to use zsh as your default shell"
echo ""

# Exit with failure if any step failed
if [[ "$SCRIPT_FAILED" == true ]]; then
    print_error "Some steps failed - review output above"
    exit 1
fi
