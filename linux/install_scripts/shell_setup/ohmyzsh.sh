#!/bin/bash
# @name: Oh My Zsh
# @description: Zsh configuration framework with plugins and themes
# @depends: shell_packages.sh, core_packages.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_ohmyzsh() {
    # Remove incomplete installation if present
    rm -rf "$HOME/.oh-my-zsh"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# Check for actual oh-my-zsh.sh file, not just directory (catches incomplete installs)
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    step "Installing Oh My Zsh" install_ohmyzsh
else
    print_skip "Oh My Zsh already installed"
fi

