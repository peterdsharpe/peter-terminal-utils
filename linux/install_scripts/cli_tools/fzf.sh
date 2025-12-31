#!/bin/bash
# @name: fzf
# @description: Command-line fuzzy finder for files, history, and more
# @repo: junegunn/fzf
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_fzf() {
    # Remove any existing/incomplete install for idempotency
    rm -rf "$HOME/.fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || return 1
    "$HOME/.fzf/install" --bin || return 1
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
}

ensure_command "fzf" fzf install_fzf

