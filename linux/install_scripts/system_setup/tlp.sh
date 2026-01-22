#!/bin/bash
# @name: TLP
# @description: Install TLP for automatic laptop power management
# @requires: sudo
# @headless: skip
# @depends: bootstrap.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "TLP"

# Check if system has a battery (skip on desktops)
has_battery() {
    [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]
}

install_tlp() {
    # Skip if no battery (desktop systems)
    if ! has_battery; then
        print_skip "TLP (no battery detected - desktop system)"
        return 0
    fi
    
    # Check if already installed and running
    if command -v tlp &>/dev/null && systemctl is-active tlp.service &>/dev/null; then
        print_skip "TLP already installed and running"
        return 0
    fi
    
    # TLP conflicts with power-profiles-daemon (GNOME's default power management)
    # Mask it if installed (even if not currently active) to prevent future conflicts
    if systemctl list-unit-files power-profiles-daemon.service &>/dev/null 2>&1; then
        local ppd_status
        ppd_status=$(systemctl is-enabled power-profiles-daemon.service 2>/dev/null || echo "not-found")
        if [[ "$ppd_status" != "masked" && "$ppd_status" != "not-found" ]]; then
            step_start "Disabling power-profiles-daemon (conflicts with TLP)"
            run sudo systemctl stop power-profiles-daemon.service 2>/dev/null || true
            run sudo systemctl mask power-profiles-daemon.service
            step_end
        fi
    fi
    
    step_start "Installing TLP"
    run pkg_install tlp
    step_end
    
    step_start "Enabling TLP service"
    run sudo systemctl enable tlp.service
    run sudo systemctl start tlp.service
    step_end
    
    # Show current status
    print_info "TLP is now managing power. Run 'sudo tlp-stat -s' to see status."
}

require_sudo "TLP" install_tlp
