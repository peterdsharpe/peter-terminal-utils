#!/bin/bash
# @name: Signal Desktop
# @description: Encrypted messaging app via Flatpak (cross-distro)
# @depends: flatpak_apps.sh
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Signal Desktop"

# Check if already installed (flatpak or native)
if command -v signal-desktop &>/dev/null || flatpak list --app 2>/dev/null | grep -q "org.signal.Signal"; then
    print_skip "Signal Desktop already installed"
    exit 0
fi

# Install via Flatpak (cross-distro)
if command -v flatpak &>/dev/null; then
    step "Installing Signal Desktop via Flatpak" flatpak install -y --user flathub org.signal.Signal
else
    print_skip "Signal Desktop (flatpak not available - install flatpak_apps.sh first)"
fi
