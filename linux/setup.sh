#!/bin/bash
set -e  # Exit on error

###############################################################################
### Script Setup
###############################################################################

# Get script directory (where dotfiles are stored)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

### Helper function for Y/N prompts
prompt_yn() {
    local prompt="$1"
    local default="$2"
    local response
    read -r -p "$prompt " response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy] ]]
}

### Interactive configuration questions
echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                         Linux Setup Script                                    ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

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

echo ""
print_info "Configuration: HEADLESS=$HEADLESS, INSTALL_SNAPS=$INSTALL_SNAPS"

###############################################################################
### System Packages (apt-get)
###############################################################################

print_header "System Packages"

print_step "Updating package lists..."
sudo apt-get update

# Core packages (always installed)
PACKAGES=(
    zsh git vim neovim tmux htop screen curl wget
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
sudo apt-get install -y "${PACKAGES[@]}"
print_success "System packages installed"

###############################################################################
### Manual CLI Tool Installs
###############################################################################

print_header "CLI Tools"

### Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
    print_step "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
    print_success "GitHub CLI installed"
else
    print_skip "GitHub CLI already installed"
fi

### Install lazygit
if ! command -v lazygit &> /dev/null; then
    print_step "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
    print_success "lazygit installed"
else
    print_skip "lazygit already installed"
fi

### Install Docker
if ! command -v docker &> /dev/null; then
    print_step "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    print_success "Docker installed"
    print_warning "Log out and back in to use docker without sudo"
else
    print_skip "Docker already installed"
fi

###############################################################################
### Fonts
###############################################################################

print_header "Fonts"

mkdir -p ~/.local/share/fonts

### Install Fira Code Nerd Font (for terminal icons)
if ! fc-list | grep -qi "FiraCode Nerd Font"; then
    print_step "Installing Fira Code Nerd Font..."
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip
    unzip -o FiraCode.zip -d ~/.local/share/fonts
    rm FiraCode.zip
    print_success "Fira Code Nerd Font installed"
else
    print_skip "Fira Code Nerd Font already installed"
fi

### Install Symbols Nerd Font (fallback for missing glyphs)
if ! fc-list | grep -qi "Symbols Nerd Font"; then
    print_step "Installing Symbols Nerd Font..."
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz
    tar -xf NerdFontsSymbolsOnly.tar.xz -C ~/.local/share/fonts
    rm NerdFontsSymbolsOnly.tar.xz
    print_success "Symbols Nerd Font installed"
else
    print_skip "Symbols Nerd Font already installed"
fi

print_step "Rebuilding font cache..."
fc-cache -fv > /dev/null 2>&1
print_success "Font cache updated"

### Configure fontconfig to use Symbols Nerd Font as fallback
print_step "Configuring fontconfig fallback..."
mkdir -p ~/.config/fontconfig
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
    gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false 2>/dev/null || true
    print_success "Touchpad tap-and-drag disabled"

    # Disable animations (snappier feel)
    print_step "Disabling GNOME animations..."
    gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
    print_success "GNOME animations disabled"

    # Faster keyboard repeat (productivity boost for terminal/vim)
    print_step "Configuring faster keyboard repeat..."
    gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.keyboard delay 200 2>/dev/null || true
    print_success "Keyboard repeat: 200ms delay, 25ms interval"

    # Flat mouse acceleration (consistent 1:1 movement)
    print_step "Setting flat mouse acceleration..."
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat' 2>/dev/null || true
    print_success "Mouse acceleration set to flat"

    # Disable hot corners (prevents accidental Activities trigger)
    print_step "Disabling hot corners..."
    gsettings set org.gnome.desktop.interface enable-hot-corners false 2>/dev/null || true
    print_success "Hot corners disabled"

    # Locate pointer with Ctrl (useful for multi-monitor)
    print_step "Enabling locate pointer with Ctrl..."
    gsettings set org.gnome.desktop.interface locate-pointer true 2>/dev/null || true
    print_success "Locate pointer enabled"

    # Show battery percentage
    print_step "Enabling battery percentage display..."
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
    print_success "Battery percentage enabled"

    # Show weekday in clock
    print_step "Enabling weekday in clock..."
    gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    print_success "Weekday in clock enabled"

    # Tap to click
    print_step "Enabling tap to click..."
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    print_success "Tap to click enabled"

    # Two-finger right click
    print_step "Enabling two-finger right click..."
    gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers' 2>/dev/null || true
    print_success "Two-finger right click enabled"

    # Center new windows
    print_step "Enabling center new windows..."
    gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    print_success "Center new windows enabled"

    # Prefer dark theme
    print_step "Setting dark theme..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    print_success "Dark theme set"

    # Set Nemo as default file manager
    print_step "Setting Nemo as default file manager..."
    xdg-mime default nemo.desktop inode/directory 2>/dev/null || true
    print_success "Nemo set as default file manager"

    # Nemo file manager settings
    print_step "Configuring Nemo file manager..."
    gsettings set org.nemo.preferences show-hidden-files true 2>/dev/null || true
    gsettings set org.nemo.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    gsettings set org.nemo.preferences sort-directories-first true 2>/dev/null || true
    print_success "Nemo configured (show hidden, list view, folders first)"

    # Nautilus file manager settings (fallback if installed)
    gsettings set org.gnome.nautilus.preferences show-hidden-files true 2>/dev/null || true
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    gsettings set org.gnome.nautilus.preferences sort-directories-first true 2>/dev/null || true
fi

###############################################################################
### SSH Setup
###############################################################################

print_header "SSH Setup"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    print_step "Generating SSH key pair..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "peterdsharpe@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
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
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    print_success "Oh My Zsh installed"
else
    print_skip "Oh My Zsh already installed"
fi

### Install Oh My Zsh plugins (skip if already cloned)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_step "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    print_success "zsh-syntax-highlighting installed"
else
    print_skip "zsh-syntax-highlighting already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_step "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    print_success "zsh-autosuggestions installed"
else
    print_skip "zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
    print_step "Installing zsh-history-substring-search plugin..."
    git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    print_success "zsh-history-substring-search installed"
else
    print_skip "zsh-history-substring-search already installed"
fi

### Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    print_step "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    print_success "Powerlevel10k installed"
else
    print_skip "Powerlevel10k already installed"
fi

### Symlink .zshrc from dotfiles
print_step "Symlinking .zshrc..."
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    # Backup existing .zshrc if it's not already a symlink
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_info "Existing .zshrc backed up"
fi
ln -sf "$SCRIPT_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
print_success ".zshrc symlinked from dotfiles"

### Copy Powerlevel10k config if it doesn't exist (or prompt to overwrite)
if [ ! -f "$HOME/.p10k.zsh" ]; then
    print_step "Copying Powerlevel10k config..."
    cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
    print_success "Powerlevel10k config installed"
else
    if prompt_yn "Powerlevel10k config already exists. Overwrite with saved config? [y/N]" "N"; then
        cp "$SCRIPT_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
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
    curl -LsSf https://astral.sh/uv/install.sh | sh
    print_success "uv installed"
else
    print_skip "uv already installed"
fi

### Install Python tools via uv
print_step "Installing Python tools (ruff, ty)..."
~/.local/bin/uv tool install ruff 2>/dev/null || true
~/.local/bin/uv tool install ty 2>/dev/null || true
print_success "Python tools installed"

### Install fnm (Node.js version manager)
if ! command -v fnm &> /dev/null; then
    print_step "Installing fnm (Node.js version manager)..."
    curl -fsSL https://fnm.vercel.app/install | bash
    print_success "fnm installed"
else
    print_skip "fnm already installed"
fi

### Install Rust
if ! command -v rustup &> /dev/null; then
    print_step "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    print_success "Rust installed"
else
    print_skip "Rust already installed"
fi

### Install Cursor CLI
if ! command -v cursor-agent &> /dev/null; then
    print_step "Installing Cursor CLI..."
    curl -fsSL https://cursor.com/install | bash
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
    sudo snap install obsidian --classic
    sudo snap install signal-desktop
    sudo snap install zotero-snap
    sudo snap install code --classic
    print_success "Snap applications installed"
else
    print_skip "Snap installations disabled"
fi

###############################################################################
### Git Configuration
###############################################################################

print_header "Git Configuration"

print_step "Configuring git..."
git config --global user.name "Peter Sharpe"
git config --global user.email "peterdsharpe@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor "nvim"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate"
print_success "Git configured"

###############################################################################
### Final Steps
###############################################################################

print_header "Final Steps"

### Load Dash to Panel settings hint (only if not headless)
if [[ "$HEADLESS" == "N" ]]; then
    if command -v dconf &> /dev/null && [ -f "$SCRIPT_DIR/dash-to-panel-settings" ]; then
        print_info "To apply Dash to Panel settings, first install the extension via Extension Manager, then run:"
        echo "  dconf load /org/gnome/shell/extensions/dash-to-panel/ < $SCRIPT_DIR/dash-to-panel-settings"
    fi
fi

### Change default shell to zsh (skip if already zsh)
if [ "$SHELL" != "$(which zsh)" ]; then
    print_step "Changing default shell to zsh..."
    chsh -s $(which zsh)
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

# Powerlevel10k configuration reminder
print_info "Customize your prompt (on first zsh launch, or anytime):"
echo "    p10k configure"
echo ""

print_warning "Log out and back in to use zsh as your default shell"
echo ""
