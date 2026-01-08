#!/bin/bash
# @name: Signal Desktop
# @description: Encrypted messaging app via Snap
# @depends: 
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

# Install via Snap
if command -v snap &>/dev/null; then
    step "Installing Signal Desktop via Snap" sudo snap install signal-desktop
else
    print_error "Signal Desktop installation failed: snapd not available"
    exit 1
fi
