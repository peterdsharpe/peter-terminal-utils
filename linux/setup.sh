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

### Command wrapper - respects dry-run mode, logs errors but continues
run() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] $*"
    elif ! "$@" 2>/dev/null; then
        print_error "Command failed: $*"
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

### Cache sudo credentials upfront
print_step "This script requires sudo privileges..."
sudo -v
print_success "Sudo credentials temporarily cached."

# Keep sudo credentials alive in background during script execution
(while true; do sudo -v; sleep 60; done) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

echo ""

if prompt_yn "Dry run (preview changes without making them)? [y/N]" "N"; then
    DRY_RUN=true
    print_warning "DRY RUN MODE - no changes will be made"
    echo ""
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

###############################################################################
### System Packages (apt-get)
###############################################################################

print_header "System Packages"

print_step "Updating package lists..."
run sudo apt-get update -qq

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

print_step "Installing packages: ${PACKAGES[*]}"
run sudo apt-get install -yq "${PACKAGES[@]}"
print_success "System packages installed"

###############################################################################
### Manual CLI Tool Installs
###############################################################################

print_header "CLI Tools"

### Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
    print_step "Installing GitHub CLI..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install GitHub CLI via apt repository"
    else
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -yq gh
    fi
    print_success "GitHub CLI installed"
else
    print_skip "GitHub CLI already installed"
fi

### Install lazygit
if ! command -v lazygit &> /dev/null; then
    print_step "Installing lazygit..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install lazygit for ${ARCH}"
    else
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi
    print_success "lazygit installed"
else
    print_skip "lazygit already installed"
fi

### Install Docker
if ! command -v docker &> /dev/null; then
    print_step "Installing Docker..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install Docker via get.docker.com"
    else
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$USER"
    fi
    print_success "Docker installed"
    print_warning "Log out and back in to use docker without sudo"
else
    print_skip "Docker already installed"
fi

###############################################################################
### Fonts
###############################################################################

print_header "Fonts"

run mkdir -p ~/.local/share/fonts

### Install Fira Code Nerd Font (for terminal icons)
if ! fc-list | grep -i "FiraCode Nerd Font" > /dev/null; then
    print_step "Installing Fira Code Nerd Font..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install Fira Code Nerd Font"
    else
        curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip
        unzip -o FiraCode.zip -d ~/.local/share/fonts
        rm FiraCode.zip
    fi
    print_success "Fira Code Nerd Font installed"
else
    print_skip "Fira Code Nerd Font already installed"
fi

### Install Symbols Nerd Font (fallback for missing glyphs)
if ! fc-list | grep -i "Symbols Nerd Font" > /dev/null; then
    print_step "Installing Symbols Nerd Font..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install Symbols Nerd Font"
    else
        curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz
        tar -xf NerdFontsSymbolsOnly.tar.xz -C ~/.local/share/fonts
        rm NerdFontsSymbolsOnly.tar.xz
    fi
    print_success "Symbols Nerd Font installed"
else
    print_skip "Symbols Nerd Font already installed"
fi

print_step "Rebuilding font cache..."
run fc-cache -fv > /dev/null 2>&1
print_success "Font cache updated"

### Configure fontconfig to use Symbols Nerd Font as fallback
print_step "Configuring fontconfig fallback..."
run mkdir -p ~/.config/fontconfig
if [[ "$DRY_RUN" == true ]]; then
    print_info "[DRY RUN] Would write ~/.config/fontconfig/fonts.conf"
else
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
fi
print_success "Fontconfig configured"

### GNOME settings (only if not headless)
if [[ "$HEADLESS" == "N" ]]; then
    # Set GNOME Terminal font
    print_step "Configuring GNOME Terminal font..."
    GNOME_TERMINAL_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)
    if [ -n "$GNOME_TERMINAL_PROFILE" ]; then
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_TERMINAL_PROFILE}/" font 'FiraCode Nerd Font Mono 11'
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_TERMINAL_PROFILE}/" use-system-font false
        print_success "GNOME Terminal font configured"
    else
        print_warning "Could not detect GNOME Terminal profile - set font manually"
    fi

    # Disable tap-and-drag (reduces touchpad latency)
    print_step "Disabling touchpad tap-and-drag..."
    run gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
    print_success "Touchpad tap-and-drag disabled"

    # Disable animations (snappier feel)
    print_step "Disabling GNOME animations..."
    run gsettings set org.gnome.desktop.interface enable-animations false
    print_success "GNOME animations disabled"

    # Faster keyboard repeat (productivity boost for terminal/vim)
    print_step "Configuring faster keyboard repeat..."
    run gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
    run gsettings set org.gnome.desktop.peripherals.keyboard delay 200
    print_success "Keyboard repeat: 200ms delay, 25ms interval"

    # Disable hot corners (prevents accidental Activities trigger)
    print_step "Disabling hot corners..."
    run gsettings set org.gnome.desktop.interface enable-hot-corners false
    print_success "Hot corners disabled"

    # Locate pointer with Ctrl (useful for multi-monitor)
    print_step "Enabling locate pointer with Ctrl..."
    run gsettings set org.gnome.desktop.interface locate-pointer true
    print_success "Locate pointer enabled"

    # Show battery percentage
    print_step "Enabling battery percentage display..."
    run gsettings set org.gnome.desktop.interface show-battery-percentage true
    print_success "Battery percentage enabled"

    # Show weekday in clock
    print_step "Enabling weekday in clock..."
    run gsettings set org.gnome.desktop.interface clock-show-weekday true
    print_success "Weekday in clock enabled"

    # Tap to click
    print_step "Enabling tap to click..."
    run gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    print_success "Tap to click enabled"

    # Two-finger right click
    print_step "Enabling two-finger right click..."
    run gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
    print_success "Two-finger right click enabled"

    # Center new windows
    print_step "Enabling center new windows..."
    run gsettings set org.gnome.mutter center-new-windows true
    print_success "Center new windows enabled"

    # Prefer dark theme
    print_step "Setting dark theme..."
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    print_success "Dark theme set"

    # Set Nemo as default file manager
    print_step "Setting Nemo as default file manager..."
    run xdg-mime default nemo.desktop inode/directory
    print_success "Nemo set as default file manager"

    # Nemo file manager settings
    print_step "Configuring Nemo file manager..."
    run gsettings set org.nemo.preferences show-hidden-files true
    run gsettings set org.nemo.preferences default-folder-viewer 'list-view'
    run gsettings set org.nemo.preferences sort-directories-first true
    print_success "Nemo configured (show hidden, list view, folders first)"

    # Nautilus file manager settings (only if installed)
    if command -v nautilus &> /dev/null; then
        print_step "Configuring Nautilus file manager..."
        run gsettings set org.gnome.nautilus.preferences show-hidden-files true
        run gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
        print_success "Nautilus configured"
    fi
fi

###############################################################################
### SSH Setup
###############################################################################

print_header "SSH Setup"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    print_step "Generating SSH key pair..."
    run mkdir -p "$HOME/.ssh"
    run chmod 700 "$HOME/.ssh"
    run ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
    print_success "SSH key pair generated"
    echo ""
    print_info "Your public key:"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    print_info "Add this key to GitHub: https://github.com/settings/ssh/new"
else
    print_skip "SSH key already exists"
fi

###############################################################################
### Shell Setup
###############################################################################

print_header "Shell Setup"

### Install Oh My Zsh (non-interactive, skip if already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_step "Installing Oh My Zsh..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install Oh My Zsh"
    else
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    print_success "Oh My Zsh installed"
else
    print_skip "Oh My Zsh already installed"
fi

### Install Oh My Zsh plugins (skip if already cloned)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_step "Installing zsh-syntax-highlighting plugin..."
    run git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    print_success "zsh-syntax-highlighting installed"
else
    print_skip "zsh-syntax-highlighting already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_step "Installing zsh-autosuggestions plugin..."
    run git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    print_success "zsh-autosuggestions installed"
else
    print_skip "zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
    print_step "Installing zsh-history-substring-search plugin..."
    run git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    print_success "zsh-history-substring-search installed"
else
    print_skip "zsh-history-substring-search already installed"
fi

### Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    print_step "Installing Powerlevel10k theme..."
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    print_success "Powerlevel10k installed"
else
    print_skip "Powerlevel10k already installed"
fi

### Symlink .zshrc from dotfiles
print_step "Symlinking .zshrc..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    # Backup existing .zshrc if it's not already a symlink
    run mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Existing .zshrc backed up"
fi
run ln -sf "$SCRIPT_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
print_success ".zshrc symlinked from dotfiles"

### Copy Powerlevel10k config if it doesn't exist (or prompt to overwrite)
if [ ! -f "$HOME/.p10k.zsh" ]; then
    print_step "Copying Powerlevel10k config..."
    run cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
    print_success "Powerlevel10k config installed"
else
    if prompt_yn "Powerlevel10k config already exists. Overwrite with saved config? [y/N]" "N"; then
        run cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
        print_success "Powerlevel10k config overwritten"
    else
        print_skip "Keeping existing Powerlevel10k config"
    fi
fi

###############################################################################
### Development Tools
###############################################################################

print_header "Development Tools"

### Install uv (Python)
if ! command -v uv &> /dev/null; then
    print_step "Installing uv (Python package manager)..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install uv via astral.sh"
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    print_success "uv installed"
else
    print_skip "uv already installed"
fi

### Install Python tools via uv
print_step "Installing Python tools (ruff, ty)..."
run ~/.local/bin/uv tool install ruff
run ~/.local/bin/uv tool install ty
print_success "Python tools installed"

### Install Rust
if ! command -v rustup &> /dev/null; then
    print_step "Installing Rust..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install Rust via rustup.rs"
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    print_success "Rust installed"
else
    print_skip "Rust already installed"
fi

### Install Cursor CLI
if ! command -v cursor-agent &> /dev/null; then
    print_step "Installing Cursor CLI..."
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would install Cursor CLI"
    else
        curl -fsSL https://cursor.com/install | bash
    fi
    print_success "Cursor CLI installed"
else
    print_skip "Cursor CLI already installed"
fi

###############################################################################
### Snap Applications
###############################################################################

print_header "Snap Applications"

if [[ "$INSTALL_SNAPS" == "Y" ]]; then
    print_step "Installing snap applications..."
    run sudo snap install obsidian --classic
    run sudo snap install signal-desktop
    run sudo snap install zotero-snap
    run sudo snap install code --classic
    print_success "Snap applications installed"
else
    print_skip "Snap installations disabled"
fi

###############################################################################
### Git Configuration
###############################################################################

print_header "Git Configuration"

print_step "Configuring git..."
run git config --global user.name "$GIT_NAME"
run git config --global user.email "$GIT_EMAIL"
run git config --global init.defaultBranch main
run git config --global pull.rebase true
run git config --global core.editor "nvim"
run git config --global alias.st status
run git config --global alias.co checkout
run git config --global alias.br branch
run git config --global alias.lg "log --oneline --graph --decorate"
print_success "Git configured"

###############################################################################
### Final Steps
###############################################################################

print_header "Final Steps"

### Install Dash to Panel extension (only if not headless)
if [[ "$HEADLESS" == "N" ]]; then
    if command -v gnome-extensions &> /dev/null; then
        EXTENSION_UUID="dash-to-panel@jderose9.github.com"
        if ! gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
            print_step "Installing Dash to Panel extension..."
            if [[ "$DRY_RUN" == true ]]; then
                print_info "[DRY RUN] Would install Dash to Panel extension"
            else
                # Get GNOME Shell version (major only)
                SHELL_VERSION=$(gnome-shell --version | grep -oP '\d+' | head -1)
                # Get download URL from extensions.gnome.org API
                DOWNLOAD_PATH=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$EXTENSION_UUID&shell_version=$SHELL_VERSION" | jq -r '.download_url // empty')
                if [ -n "$DOWNLOAD_PATH" ]; then
                    curl -sL "https://extensions.gnome.org$DOWNLOAD_PATH" -o /tmp/dash-to-panel.zip
                    gnome-extensions install --force /tmp/dash-to-panel.zip
                    rm /tmp/dash-to-panel.zip
                    print_success "Dash to Panel installed"
                else
                    print_error "Could not find Dash to Panel for GNOME Shell $SHELL_VERSION"
                fi
            fi
        else
            print_skip "Dash to Panel already installed"
        fi

        # Enable extension and load settings
        if gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
            print_step "Enabling Dash to Panel..."
            run gnome-extensions enable "$EXTENSION_UUID"
            print_success "Dash to Panel enabled"

            if [ -f "$SCRIPT_DIR/dash-to-panel-settings" ]; then
                print_step "Loading Dash to Panel settings..."
                run dconf load /org/gnome/shell/extensions/dash-to-panel/ < "$SCRIPT_DIR/dash-to-panel-settings"
                print_success "Dash to Panel settings loaded"
            fi
        fi
    fi
fi

### Change default shell to zsh (skip if already zsh)
if [ "$SHELL" != "$(which zsh)" ]; then
    print_step "Changing default shell to zsh..."
    run sudo chsh -s "$(which zsh)" "$USER"
    print_success "Default shell changed to zsh"
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

print_warning "Log out and back in to use zsh as your default shell"
echo ""
