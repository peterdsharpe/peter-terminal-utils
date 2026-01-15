#!/bin/bash
# @name: Symbols Nerd Font
# @description: Fallback font for missing glyphs and icons
# @depends: core_packages.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_symbols_font() {
    local tmpdir
    tmpdir=$(mktemp -d) || return 1
    curl -fL -o "$tmpdir/NerdFontsSymbolsOnly.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz || { rm -rf "$tmpdir"; return 1; }
    mkdir -p ~/.local/share/fonts
    tar -xf "$tmpdir/NerdFontsSymbolsOnly.tar.xz" -C ~/.local/share/fonts || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

# Check if already installed (prefer file check over fc-list for reliability)
font_installed() {
    # Check for font files directly (most reliable)
    ls ~/.local/share/fonts/*Symbols*Nerd* &>/dev/null && return 0
    # Fallback to fc-list if fontconfig is available
    command -v fc-list &>/dev/null && fc-list | grep -qi "Symbols.*Nerd" && return 0
    return 1
}

if ! font_installed; then
    step "Installing Symbols Nerd Font" install_symbols_font
    # Rebuild font cache if fontconfig is available
    if command -v fc-cache &>/dev/null; then
        step "Rebuilding font cache" fc-cache -f
    fi
else
    print_skip "Symbols Nerd Font already installed"
fi

