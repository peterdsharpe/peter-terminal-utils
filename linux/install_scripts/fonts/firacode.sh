#!/bin/bash
# @name: Fira Code Nerd Font
# @description: Programming font with ligatures and icons
# @depends: core_packages.sh
# @parallel: true
# @resource: network
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

# Check if already installed (prefer file check over fc-list for reliability)
font_installed() {
    # Check for font files directly (most reliable)
    ls ~/.local/share/fonts/*FiraCode*Nerd* &>/dev/null && return 0
    # Fallback to fc-list if fontconfig is available
    command -v fc-list &>/dev/null && fc-list | grep -qi "FiraCode.*Nerd" && return 0
    return 1
}

if ! font_installed; then
    step "Installing Fira Code Nerd Font" install_firacode
    # Rebuild font cache if fontconfig is available
    if command -v fc-cache &>/dev/null; then
        step "Rebuilding font cache" fc-cache -f
    fi
else
    print_skip "Fira Code Nerd Font already installed"
fi

