#!/bin/bash
# @name: Just Perfection
# @description: GNOME extension to disable animations and popup delays
# @depends: core_packages.sh
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Just Perfection"
skip_if_not_gnome "Just Perfection"

# Only run if gnome-extensions is available
if ! command -v gnome-extensions &> /dev/null; then
    print_skip "Just Perfection (gnome-extensions not available)"
    exit 0
fi

JUST_PERFECTION_UUID="just-perfection-desktop@just-perfection"

install_just_perfection() {
    local shell_version download_path api_response tmpzip
    
    shell_version=$(gnome-shell --version | grep -oP '\d+' | head -1) || {
        echo "Could not determine GNOME Shell version" >&2
        return 1
    }
    
    api_response=$(curl -sf --connect-timeout 10 "https://extensions.gnome.org/extension-info/?uuid=$JUST_PERFECTION_UUID&shell_version=$shell_version") || {
        echo "Failed to fetch extension info from extensions.gnome.org" >&2
        return 1
    }
    
    download_path=$(echo "$api_response" | jq -r '.download_url // empty')
    [ -n "$download_path" ] || { echo "No download URL for Just Perfection (shell version $shell_version may be unsupported)" >&2; return 1; }
    
    tmpzip=$(mktemp --suffix=.zip) || return 1
    if ! curl -sfL "https://extensions.gnome.org$download_path" -o "$tmpzip"; then
        rm -f "$tmpzip"
        return 1
    fi
    gnome-extensions install --force "$tmpzip" || { rm -f "$tmpzip"; return 1; }
    rm -f "$tmpzip"
}

if ! gnome-extensions list | grep -q "$JUST_PERFECTION_UUID" 2>&1; then
    step "Installing Just Perfection extension" install_just_perfection
else
    print_skip "Just Perfection already installed"
fi

if gnome-extensions list | grep -q "$JUST_PERFECTION_UUID" 2>&1; then
    step "Enabling Just Perfection" gnome-extensions enable "$JUST_PERFECTION_UUID"
    step "Disabling Alt+Tab popup delay" dconf write /org/gnome/shell/extensions/just-perfection/switcher-popup-delay true
    step "Disabling animations" dconf write /org/gnome/shell/extensions/just-perfection/animation 0
fi
