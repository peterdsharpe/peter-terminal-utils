#!/bin/bash
# @name: PackageKit
# @description: Disable PackageKit to reduce memory usage (GUI software centers still work on-demand)
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

### PackageKit ###
# PackageKit is a D-Bus abstraction layer for GUI software centers (GNOME Software, KDE Discover).
# Known to consume excessive memory when running. We disable (not mask) it so:
#   - It won't auto-start at boot or poll in the background
#   - GUI software centers still work on-demand via D-Bus activation
# If you never use GUI package managers, you can `systemctl mask packagekit` instead.

disable_packagekit() {
    # Skip if packagekit isn't installed
    if ! systemctl list-unit-files packagekit.service &>/dev/null; then
        print_skip "PackageKit not installed"
        return 0
    fi
    
    # Check current state
    # Note: systemctl is-enabled returns exit code 1 for "disabled", so we must ignore the exit code
    local is_enabled is_active
    is_enabled=$(systemctl is-enabled packagekit.service 2>/dev/null) || true
    is_active=$(systemctl is-active packagekit.service 2>/dev/null) || true
    [[ -z "$is_enabled" ]] && is_enabled="unknown"
    [[ -z "$is_active" ]] && is_active="unknown"
    
    if [[ "$is_enabled" == "disabled" && "$is_active" != "active" ]]; then
        print_skip "PackageKit already disabled and stopped"
        return 0
    fi
    
    step_start "Disabling PackageKit service"
    
    if [[ "$is_enabled" != "disabled" ]]; then
        run sudo systemctl disable packagekit.service
    fi
    
    if [[ "$is_active" == "active" ]]; then
        run sudo systemctl stop packagekit.service
    fi
    
    step_end
}

require_sudo "PackageKit" disable_packagekit
