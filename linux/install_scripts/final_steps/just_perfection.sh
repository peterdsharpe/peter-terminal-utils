#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Install and configure Just Perfection GNOME extension

# Only run if not headless
if [[ "$HEADLESS" == "Y" ]]; then
    print_skip "Just Perfection (headless mode)"
    exit 0
fi

# Only run if gnome-extensions is available
if ! command -v gnome-extensions &> /dev/null; then
    print_skip "Just Perfection (gnome-extensions not available)"
    exit 0
fi

JUST_PERFECTION_UUID="just-perfection-desktop@just-perfection"

install_just_perfection() {
    local shell_version download_path
    shell_version=$(gnome-shell --version | grep -oP '\d+' | head -1) || return 1
    download_path=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$JUST_PERFECTION_UUID&shell_version=$shell_version" | jq -r '.download_url // empty') || return 1
    [ -n "$download_path" ] || { echo "No download URL found for Just Perfection extension" >&2; return 1; }
    curl -sL "https://extensions.gnome.org$download_path" -o /tmp/just-perfection.zip || return 1
    gnome-extensions install --force /tmp/just-perfection.zip || return 1
    rm /tmp/just-perfection.zip
}

if ! gnome-extensions list | grep -q "$JUST_PERFECTION_UUID" 2>&1; then
    step "Installing Just Perfection extension" install_just_perfection
else
    print_skip "Just Perfection already installed"
fi

if gnome-extensions list | grep -q "$JUST_PERFECTION_UUID" 2>&1; then
    step "Enabling Just Perfection" gnome-extensions enable "$JUST_PERFECTION_UUID"
    step "Disabling Alt+Tab popup delay" dconf write /org/gnome/shell/extensions/just-perfection/switcher-popup-delay false
fi

