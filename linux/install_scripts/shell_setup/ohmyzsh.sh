#!/bin/bash
# @name: Oh My Zsh
# @description: Zsh configuration framework with plugins and themes
# @depends: shell_packages.sh, bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Oh My Zsh uses its own installer for initial setup, but we can use git pull for updates
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    # Fresh install: use official installer (sets up structure correctly)
    install_ohmyzsh() {
        rm -rf "$HOME/.oh-my-zsh"
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    }
    step "Installing Oh My Zsh" install_ohmyzsh
elif [ -d "$HOME/.oh-my-zsh/.git" ]; then
    # Already installed with git: update it
    step "Updating Oh My Zsh" git -C "$HOME/.oh-my-zsh" pull --ff-only
else
    print_skip "Oh My Zsh already installed"
fi

