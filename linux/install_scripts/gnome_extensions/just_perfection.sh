#!/bin/bash
# @name: Just Perfection
# @description: GNOME extension to disable animations and popup delays
# @depends: bootstrap.sh
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Just Perfection"
skip_if_not_gnome "Just Perfection"

EXTENSION_UUID="just-perfection-desktop@just-perfection"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"

# Install/update extension (handles version checking internally)
ensure_gnome_extension "$EXTENSION_UUID" "Just Perfection"

# Check if GNOME Shell knows about the extension (only true after session restart)
if gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
    # Extension is loaded by GNOME Shell - enable and configure
    step "Enabling Just Perfection" gnome-extensions enable "$EXTENSION_UUID"
    step "Disabling Alt+Tab popup delay" dconf write /org/gnome/shell/extensions/just-perfection/switcher-popup-delay true
    step "Disabling animations" dconf write /org/gnome/shell/extensions/just-perfection/animation 0
elif [[ -d "$EXTENSION_DIR" ]]; then
    # Extension is installed but GNOME Shell hasn't loaded it yet
    print_warning "Just Perfection installed but requires log out/in to enable"
fi
