#!/bin/bash
# @name: Default Shell
# @description: Change default shell to zsh
# @depends: shell_packages.sh
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

change_default_shell() {
    step "Changing default shell to zsh" sudo chsh -s "$(which zsh)" "$USER"
}

if [ "$SHELL" != "$(which zsh)" ]; then
    require_sudo "Default shell change" change_default_shell
else
    print_skip "Shell is already zsh"
fi
