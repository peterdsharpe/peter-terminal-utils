#!/bin/bash
set -e  # Exit on error

### Install essential packages
sudo apt-get update
sudo apt-get install -y \
    zsh git vim neovim tmux htop screen curl wget \
    build-essential \
    ripgrep fd-find fzf bat eza tree ncdu jq \
    unzip zip \
    net-tools openssh-server \
    nemo \
    gnome-shell-extension-manager gnome-tweaks \
    vlc dconf-editor zoxide

### Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
else
    echo "GitHub CLI already installed, skipping."
fi

### Install lazygit
if ! command -v lazygit &> /dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
else
    echo "lazygit already installed, skipping."
fi

### Install Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Log out and back in to use docker without sudo."
else
    echo "Docker already installed, skipping."
fi

### Configure Git
git config --global user.name "Peter Sharpe"
git config --global user.email "peterdsharpe@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global core.editor "nvim"
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate"

### Install JetBrains Mono Nerd Font (for terminal icons)
mkdir -p ~/.local/share/fonts
if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    tar -xf JetBrainsMono.tar.xz -C ~/.local/share/fonts
    rm JetBrainsMono.tar.xz
else
    echo "JetBrains Mono Nerd Font already installed, skipping."
fi

### Install Symbols Nerd Font (fallback for missing glyphs)
if ! fc-list | grep -qi "Symbols Nerd Font"; then
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz
    tar -xf NerdFontsSymbolsOnly.tar.xz -C ~/.local/share/fonts
    rm NerdFontsSymbolsOnly.tar.xz
else
    echo "Symbols Nerd Font already installed, skipping."
fi
fc-cache -fv

### Configure fontconfig to use Symbols Nerd Font as fallback
mkdir -p ~/.config/fontconfig
cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any"><string>JetBrainsMono Nerd Font</string></test>
    <edit name="family" mode="append" binding="weak">
      <string>Symbols Nerd Font</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" qual="any"><string>JetBrainsMono Nerd Font Mono</string></test>
    <edit name="family" mode="append" binding="weak">
      <string>Symbols Nerd Font Mono</string>
    </edit>
  </match>
</fontconfig>
EOF

### Set GNOME Terminal font to JetBrains Mono Nerd Font
GNOME_TERMINAL_PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
if [ -n "$GNOME_TERMINAL_PROFILE" ]; then
    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_TERMINAL_PROFILE}/" font 'JetBrainsMono Nerd Font Mono 11'
    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${GNOME_TERMINAL_PROFILE}/" use-system-font false
    echo "GNOME Terminal font set to JetBrainsMono Nerd Font Mono."
else
    echo "NOTE: Could not detect GNOME Terminal profile. Set your terminal font to 'JetBrainsMono Nerd Font' manually."
fi

### Install Oh My Zsh (non-interactive, skip if already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed, skipping."
fi

### Install Oh My Zsh plugins (skip if already cloned)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

### Enable plugins in .zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search)/' ~/.zshrc

### Add aliases to .zshrc (skip if already added)
if ! grep -q "# Modern CLI aliases" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# Modern CLI aliases
alias ls="eza --icons"
alias ll="eza -la --icons"
alias cat="batcat"
alias fd="fdfind"

# Git aliases
alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -20"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Python
alias py="uv run python"
alias ipy="uv run ipython"

# Initialize zoxide (smarter cd)
eval "$(zoxide init zsh)"
EOF
else
    echo "Aliases already in .zshrc, skipping."
fi

### Install uv (Python)
curl -LsSf https://astral.sh/uv/install.sh | sh

### Install Python tools via uv
~/.local/bin/uv tool install ruff
~/.local/bin/uv tool install ty

### Install fnm (Node.js version manager)
curl -fsSL https://fnm.vercel.app/install | bash

### Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

### Install Cursor CLI
if ! command -v cursor-agent &> /dev/null; then
    curl -fsSL https://cursor.com/install | bash
else
    echo "Cursor CLI already installed, skipping."
fi

### Install snap applications
sudo snap install obsidian --classic
sudo snap install signal-desktop
sudo snap install zotero-snap
sudo snap install code --classic

### Load Dash to Panel settings (if extension is installed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v dconf &> /dev/null && [ -f "$SCRIPT_DIR/dash-to-panel-settings" ]; then
    echo "To apply Dash to Panel settings, first install the extension via Extension Manager, then run:"
    echo "  dconf load /org/gnome/shell/extensions/dash-to-panel/ < $SCRIPT_DIR/dash-to-panel-settings"
fi

### Change default shell to zsh (skip if already zsh)
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
else
    echo "Shell is already zsh, skipping."
fi

echo "Setup complete! Log out and back in to use zsh."
