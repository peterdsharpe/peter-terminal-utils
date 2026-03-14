#!/bin/bash
# @name: Nerd Fonts
# @description: Programming fonts with ligatures and icons (Fira Code + Symbols)
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

FONT_DIR="$HOME/.local/share/fonts"

# Check if a font is installed by file pattern
font_installed() {
    local pattern="$1"
    # Check for font files directly (most reliable)
    ls "$FONT_DIR"/$pattern &>/dev/null && return 0
    # Fallback to fc-list if fontconfig is available
    command -v fc-list &>/dev/null && fc-list | grep -qi "$pattern" && return 0
    return 1
}

# Install a Nerd Font from GitHub releases
install_nerd_font() {
    local name="$1"
    local archive="$2"
    local check_pattern="$3"
    
    if font_installed "$check_pattern"; then
        print_skip "$name already installed"
        return 0
    fi
    
    local tmpdir
    tmpdir=$(mktemp -d) || return 1
    
    step_start "Installing $name"
    run curl -fL -o "$tmpdir/$archive" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$archive"
    mkdir -p "$FONT_DIR"
    
    case "$archive" in
        *.zip)
            run unzip -o "$tmpdir/$archive" -d "$FONT_DIR"
            ;;
        *.tar.xz)
            run tar -xf "$tmpdir/$archive" -C "$FONT_DIR"
            ;;
    esac
    step_end
    
    rm -rf "$tmpdir"
    return "$(step_result)"
}

# Install fonts
install_nerd_font "Fira Code Nerd Font" "FiraCode.zip" "*FiraCode*Nerd*"
install_nerd_font "Symbols Nerd Font" "NerdFontsSymbolsOnly.tar.xz" "*Symbols*Nerd*"

# Rebuild font cache once at the end
if command -v fc-cache &>/dev/null; then
    step "Rebuilding font cache" fc-cache -f
fi
