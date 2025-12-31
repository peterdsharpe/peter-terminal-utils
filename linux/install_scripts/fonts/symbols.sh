#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install Symbols Nerd Font (fallback for missing glyphs)

install_symbols_font() {
    local tmpdir
    tmpdir=$(mktemp -d) || return 1
    curl -fL -o "$tmpdir/NerdFontsSymbolsOnly.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz || { rm -rf "$tmpdir"; return 1; }
    mkdir -p ~/.local/share/fonts
    tar -xf "$tmpdir/NerdFontsSymbolsOnly.tar.xz" -C ~/.local/share/fonts || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

if ! fc-list | grep -i "Symbols Nerd Font" > /dev/null; then
    step "Installing Symbols Nerd Font" install_symbols_font
else
    print_skip "Symbols Nerd Font already installed"
fi

step "Rebuilding font cache" fc-cache -f

