#!/bin/bash
# @name: Zsh Plugins
# @description: Syntax highlighting, autosuggestions, autocomplete
# @depends: ohmyzsh.sh, core_packages.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

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

