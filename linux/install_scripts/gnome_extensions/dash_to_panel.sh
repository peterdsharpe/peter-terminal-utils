#!/bin/bash
# @name: Dash to Panel
# @description: GNOME extension for Windows-style taskbar
# @depends: bootstrap.sh
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")

skip_if_headless "Dash to Panel"
skip_if_not_gnome "Dash to Panel"

EXTENSION_UUID="dash-to-panel@jderose9.github.com"

# Install/update extension (handles version checking internally)
ensure_gnome_extension "$EXTENSION_UUID" "Dash to Panel"

# Enable extension and load settings
if gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
    step "Enabling Dash to Panel" gnome-extensions enable "$EXTENSION_UUID"

    if [ -f "$LINUX_DIR/dash-to-panel-settings" ]; then
        step_start "Loading Dash to Panel settings"
        run_stdin "$LINUX_DIR/dash-to-panel-settings" dconf load /org/gnome/shell/extensions/dash-to-panel/
        step_end
    fi
fi
