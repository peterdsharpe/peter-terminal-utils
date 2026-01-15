#!/bin/bash
# @name: NetworkManager Wait Online
# @description: Disable wait-online service to speed up desktop boot
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "NetworkManager-wait-online"

# NetworkManager-wait-online.service blocks boot until network is fully up.
# On desktops this is unnecessary - you can log in and use the system while
# network connects in the background. On servers it may be useful (e.g., for
# SSH availability immediately after boot), so we skip this on headless systems.

disable_networkmanager_wait() {
    local service="NetworkManager-wait-online.service"
    
    # Skip if not installed
    if ! systemctl list-unit-files "$service" &>/dev/null; then
        print_skip "NetworkManager-wait-online not installed"
        return 0
    fi
    
    # Check current state
    local is_enabled
    is_enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "unknown")
    
    if [[ "$is_enabled" == "disabled" ]]; then
        print_skip "NetworkManager-wait-online already disabled"
        return 0
    fi
    
    step "Disabling NetworkManager-wait-online" sudo systemctl disable "$service"
}

require_sudo "NetworkManager-wait-online" disable_networkmanager_wait
