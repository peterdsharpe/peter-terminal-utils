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

# Check if already installed
if snap list signal-desktop &>/dev/null 2>&1; then
    print_skip "Signal Desktop already installed"
    exit 0
fi

# Install via Snap (requires sudo)
install_signal() {
    if command -v snap &>/dev/null; then
        step "Installing Signal Desktop via Snap" sudo snap install signal-desktop
    else
        print_error "Signal Desktop installation failed: snapd not available"
        return 1
    fi
}

require_sudo "Signal Desktop" install_signal
