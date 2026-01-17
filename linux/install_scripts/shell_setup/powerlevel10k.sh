#!/bin/bash
# @name: Powerlevel10k
# @description: Fast and beautiful zsh theme with instant prompt
# @depends: ohmyzsh.sh, bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

ensure_git_repo "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM/themes/powerlevel10k" "Powerlevel10k"

