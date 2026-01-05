#!/bin/bash
# @name: Shell Packages
# @description: Shell and terminal environment (zsh, tmux, vim, neovim)
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_shell_packages() {
    local packages=(
        zsh      # Shell (oh-my-zsh, plugins depend on this)
        tmux     # Terminal multiplexer
        vim      # Editor (fallback)
        neovim   # Editor (primary - also installed from GitHub for latest)
    )

    step_start "Installing shell packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end
}

require_sudo "Shell packages" install_shell_packages
