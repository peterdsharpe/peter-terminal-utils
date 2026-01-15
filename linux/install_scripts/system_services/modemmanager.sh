#!/bin/bash
# @name: ModemManager
# @description: Disable ModemManager for systems without cellular modems
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# ModemManager provides mobile broadband (cellular modem) support.
# Most laptops don't have cellular modems, making this service unnecessary.
# We disable (not mask) it so D-Bus activation still works if ever needed.

disable_modemmanager() {
    # Skip if ModemManager isn't installed
    if ! systemctl list-unit-files ModemManager.service &>/dev/null; then
        print_skip "ModemManager not installed"
        return 0
    fi
    
    # Check current state
    # Note: systemctl is-enabled returns exit code 1 for "disabled", so we must ignore the exit code
    local is_enabled is_active
    is_enabled=$(systemctl is-enabled ModemManager.service 2>/dev/null) || true
    is_active=$(systemctl is-active ModemManager.service 2>/dev/null) || true
    [[ -z "$is_enabled" ]] && is_enabled="unknown"
    [[ -z "$is_active" ]] && is_active="unknown"
    
    if [[ "$is_enabled" == "disabled" && "$is_active" != "active" ]]; then
        print_skip "ModemManager already disabled and stopped"
        return 0
    fi
    
    step_start "Disabling ModemManager service"
    
    if [[ "$is_enabled" != "disabled" ]]; then
        run sudo systemctl disable ModemManager.service
    fi
    
    if [[ "$is_active" == "active" ]]; then
        run sudo systemctl stop ModemManager.service
    fi
    
    step_end
}

require_sudo "ModemManager" disable_modemmanager
