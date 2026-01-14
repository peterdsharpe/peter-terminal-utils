#!/bin/bash
# @name: Dash to Panel
# @description: GNOME extension for Windows-style taskbar
# @depends: core_packages.sh
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")

skip_if_headless "Dash to Panel"
skip_if_not_gnome "Dash to Panel"

# Only run if gnome-extensions is available
if ! command -v gnome-extensions &> /dev/null; then
    print_skip "Dash to Panel (gnome-extensions not available)"
    exit 0
fi

EXTENSION_UUID="dash-to-panel@jderose9.github.com"

install_dash_to_panel() {
    local shell_version download_path api_response tmpzip
    
    shell_version=$(gnome-shell --version | grep -oP '\d+' | head -1) || {
        echo "Could not determine GNOME Shell version" >&2
        return 1
    }
    
    api_response=$(curl -sf --connect-timeout 10 "https://extensions.gnome.org/extension-info/?uuid=$EXTENSION_UUID&shell_version=$shell_version") || {
        echo "Failed to fetch extension info from extensions.gnome.org" >&2
        return 1
    }
    
    download_path=$(echo "$api_response" | jq -r '.download_url // empty')
    [ -n "$download_path" ] || { echo "No download URL for Dash to Panel (shell version $shell_version may be unsupported)" >&2; return 1; }
    
    tmpzip=$(mktemp --suffix=.zip) || return 1
    if ! curl -sfL "https://extensions.gnome.org$download_path" -o "$tmpzip"; then
        rm -f "$tmpzip"
        return 1
    fi
    gnome-extensions install --force "$tmpzip" || { rm -f "$tmpzip"; return 1; }
    rm -f "$tmpzip"
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
