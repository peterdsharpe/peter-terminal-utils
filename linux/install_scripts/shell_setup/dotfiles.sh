#!/bin/bash
# @name: Dotfiles
# @description: Symlink shell configs (.shell_common, .zshrc, .bashrc, .p10k.zsh) and nvim config
# @depends: ohmyzsh.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")

### Symlink .shell_common from dotfiles (shared config sourced by both .zshrc and .bashrc)
setup_shell_common() {
    if [ -f "$HOME/.shell_common" ] && [ ! -L "$HOME/.shell_common" ]; then
        mv "$HOME/.shell_common" "$HOME/.shell_common.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/.shell_common" "$HOME/.shell_common"
}
step "Symlinking .shell_common" setup_shell_common

### Symlink .zshrc from dotfiles
setup_zshrc() {
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
}
step "Symlinking .zshrc" setup_zshrc

### Symlink .bashrc from dotfiles
setup_bashrc() {
    if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
        mv "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/.bashrc" "$HOME/.bashrc"
}
step "Symlinking .bashrc" setup_bashrc

### Symlink neovim config from dotfiles
setup_nvim_config() {
    mkdir -p "$HOME/.config/nvim" || return 1
    if [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -L "$HOME/.config/nvim/init.vim" ]; then
        mv "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/init.vim" "$HOME/.config/nvim/init.vim"
}
step "Symlinking neovim config" setup_nvim_config

### Symlink Powerlevel10k config from dotfiles
setup_p10k() {
    if [ -f "$HOME/.p10k.zsh" ] && [ ! -L "$HOME/.p10k.zsh" ]; then
        mv "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.backup.$(date +%Y%m%d_%H%M%S)" || return 1
    fi
    ln -sf "$LINUX_DIR/dotfiles/.p10k.zsh" "$HOME/.p10k.zsh"
}
step "Symlinking Powerlevel10k config" setup_p10k

