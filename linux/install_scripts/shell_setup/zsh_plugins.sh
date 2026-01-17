#!/bin/bash
# @name: Zsh Plugins
# @description: Syntax highlighting, autosuggestions, autocomplete
# @depends: ohmyzsh.sh, bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

ensure_git_repo "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"

ensure_git_repo "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"

ensure_git_repo "https://github.com/zsh-users/zsh-history-substring-search.git" \
    "$ZSH_CUSTOM/plugins/zsh-history-substring-search" "zsh-history-substring-search"

ensure_git_repo "https://github.com/marlonrichert/zsh-autocomplete.git" \
    "$ZSH_CUSTOM/plugins/zsh-autocomplete" "zsh-autocomplete"

