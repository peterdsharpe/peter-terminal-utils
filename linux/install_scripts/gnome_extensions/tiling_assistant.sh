#!/bin/bash
# @name: Tiling Assistant
# @description: Configure Ubuntu's built-in tiling assistant extension
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Tiling Assistant configuration"
skip_if_not_gnome "Tiling Assistant configuration"

# Ubuntu ships Tiling Assistant as a built-in extension (since 23.10)
# Check if the extension schema is available before attempting configuration
if ! gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    print_skip "Tiling Assistant not installed"
    exit 0
fi

# Disable the tiling popup that appears after tiling a window
# This popup shows a window picker for the remaining screen space
step "Disabling tiling popup after window tile" \
    gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false
