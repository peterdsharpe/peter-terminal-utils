#!/bin/bash
# @name: Dotfiles
# @description: Symlink .zshrc, nvim config, .p10k.zsh
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Get the linux directory (where dotfiles are stored)
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

### Symlink .zshrc from dotfiles
setup_zshrc() {
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
}
step "Symlinking .zshrc" setup_zshrc

### Symlink neovim config from dotfiles
setup_nvim_config() {
    mkdir -p "$HOME/.config/nvim" || return 1
    if [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -L "$HOME/.config/nvim/init.vim" ]; then
        mv "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/init.vim" "$HOME/.config/nvim/init.vim"
}
step "Symlinking neovim config" setup_nvim_config

### Copy Powerlevel10k config if it doesn't exist (or prompt to overwrite)
if [ ! -f "$HOME/.p10k.zsh" ]; then
    step "Copying Powerlevel10k config" cp "$LINUX_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
else
    # In orchestrated mode, skip overwrite prompt
    if [[ "${ORCHESTRATED:-}" == "true" ]]; then
        print_skip "Keeping existing Powerlevel10k config"
    elif prompt_yn "Powerlevel10k config already exists. Overwrite with saved config? [y/N]" "N"; then
        step "Overwriting Powerlevel10k config" cp "$LINUX_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
    else
        print_skip "Keeping existing Powerlevel10k config"
    fi
fi

