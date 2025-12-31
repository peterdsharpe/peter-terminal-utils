#!/bin/bash
# @name: Dash to Panel
# @description: GNOME extension for Windows-style taskbar
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Get the linux directory (where settings file is stored)
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Only run if not headless
if [[ "$HEADLESS" == "Y" ]]; then
    print_skip "Dash to Panel (headless mode)"
    exit 0
fi

# Only run if gnome-extensions is available
if ! command -v gnome-extensions &> /dev/null; then
    print_skip "Dash to Panel (gnome-extensions not available)"
    exit 0
fi

EXTENSION_UUID="dash-to-panel@jderose9.github.com"

install_dash_to_panel() {
    local shell_version download_path
    shell_version=$(gnome-shell --version | grep -oP '\d+' | head -1) || return 1
    download_path=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$EXTENSION_UUID&shell_version=$shell_version" | jq -r '.download_url // empty') || return 1
    [ -n "$download_path" ] || { echo "No download URL found for Dash to Panel extension" >&2; return 1; }
    curl -sL "https://extensions.gnome.org$download_path" -o /tmp/dash-to-panel.zip || return 1
    gnome-extensions install --force /tmp/dash-to-panel.zip || return 1
    rm /tmp/dash-to-panel.zip
}

if ! gnome-extensions list | grep -q "$EXTENSION_UUID" 2>&1; then
    step "Installing Dash to Panel extension" install_dash_to_panel
else
    print_skip "Dash to Panel already installed"
fi

# Enable extension and load settings
if gnome-extensions list | grep -q "$EXTENSION_UUID" 2>&1; then
    step "Enabling Dash to Panel" gnome-extensions enable "$EXTENSION_UUID"

    if [ -f "$LINUX_DIR/dash-to-panel-settings" ]; then
        step_start "Loading Dash to Panel settings"
        run_stdin "$LINUX_DIR/dash-to-panel-settings" dconf load /org/gnome/shell/extensions/dash-to-panel/
        step_end
    fi
fi

