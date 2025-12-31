#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Change default shell to zsh

change_default_shell() {
    step "Changing default shell to zsh" sudo chsh -s "$(which zsh)" "$USER"
}

if [ "$SHELL" != "$(which zsh)" ]; then
    require_sudo "Default shell change" change_default_shell
else
    print_skip "Shell is already zsh"
fi

