#!/bin/bash
# @name: GNOME Terminal
# @description: Set terminal font to Fira Code Nerd Font
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "GNOME Terminal configuration"
skip_if_not_gnome "GNOME Terminal configuration"

# Set GNOME Terminal font (only if GNOME Terminal is installed)
if gsettings list-schemas | grep -q "org.gnome.Terminal" 2>/dev/null; then
    configure_gnome_terminal() {
        local profile
        profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'") || return 1
        [ -n "$profile" ] || { echo "No GNOME Terminal profile found" >&2; return 1; }
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" font 'FiraCode Nerd Font Mono 11' || return 1
        gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/" use-system-font false
    }
    step "Configuring GNOME Terminal font" configure_gnome_terminal
else
    print_skip "GNOME Terminal font (GNOME Terminal not installed)"
fi

