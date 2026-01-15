#!/bin/bash
# @name: Remmina
# @description: Remote desktop client via Snap with interface permissions
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Remmina"

# Check if snap is available first
if ! command -v snap &>/dev/null; then
    print_skip "Remmina (snapd not available)"
    exit 0
fi

# Check if already installed
if snap list remmina &>/dev/null 2>&1; then
    print_skip "Remmina already installed"
else
    # Install via Snap (requires sudo)
    install_remmina() {
        step "Installing Remmina via Snap" sudo snap install remmina
    }
    require_sudo "Remmina" install_remmina
fi

# Connect required snap interfaces (idempotent - safe to run even if already connected)
connect_interfaces() {
    local interfaces=(
        "audio-record"
        "avahi-observe"
        "cups-control"
        "mount-observe"
        "password-manager-service"
        "ssh-keys"
        "ssh-public-keys"
    )
    
    step_start "Connecting Remmina snap interfaces"
    for iface in "${interfaces[@]}"; do
        run sudo snap connect "remmina:${iface}" ":${iface}"
    done
    step_end
}

require_sudo "Remmina interface permissions" connect_interfaces
