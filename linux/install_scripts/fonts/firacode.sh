#!/bin/bash
# @name: Fira Code Nerd Font
# @description: Programming font with ligatures and icons
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_firacode() {
    local tmpdir
    tmpdir=$(mktemp -d) || return 1
    curl -fL -o "$tmpdir/FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip || { rm -rf "$tmpdir"; return 1; }
    mkdir -p ~/.local/share/fonts
    unzip -o "$tmpdir/FiraCode.zip" -d ~/.local/share/fonts || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

if ! fc-list | grep -i "FiraCode Nerd Font" > /dev/null; then
    step "Installing Fira Code Nerd Font" install_firacode
else
    print_skip "Fira Code Nerd Font already installed"
fi

