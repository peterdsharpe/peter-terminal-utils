#!/bin/bash
# @name: Signal Desktop
# @description: Encrypted messaging app via Snap
# @depends: 
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Signal Desktop"

# WSL: use Windows Signal instead
if is_wsl; then
    print_skip "Signal Desktop (use Windows version in WSL)"
    exit 0
fi

# Check if snap is available first
if ! command -v snap &>/dev/null; then
    print_skip "Signal Desktop (snapd not available)"
    exit 0
fi

# Check if already installed
if snap list signal-desktop &>/dev/null 2>&1; then
    print_skip "Signal Desktop already installed"
    exit 0
fi

# Install via Snap (requires sudo)
install_signal() {
    step "Installing Signal Desktop via Snap" sudo snap install signal-desktop
}

require_sudo "Signal Desktop" install_signal
