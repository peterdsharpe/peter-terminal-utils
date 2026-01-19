#!/bin/bash
# @name: Check Updates
# @description: Check for pending Ubuntu distribution upgrades (e.g., 22.04 to 24.04)
# @requires: sudo
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

### Check Ubuntu Distribution Upgrades ###
# This script checks whether a new Ubuntu release is available for upgrade.
# It succeeds (exit 0) if the system is on the latest available release, and
# fails (exit 1) if a distribution upgrade is available.
#
# This is distinct from package updates (handled by apt upgrade) - this checks
# for major version upgrades like 22.04 -> 24.04 or 24.04 -> 24.10.
#
# When an upgrade is available, the script logs the command to perform it,
# since distribution upgrades require interactive confirmation and often a reboot.

check_distro_upgrade() {
    # Only Ubuntu is supported - skip gracefully on other distros
    if ! is_ubuntu; then
        print_skip "Check Updates (Ubuntu only, detected: $DISTRO)"
        exit 0
    fi

    # Get current Ubuntu version for display
    local current_version
    current_version=$(lsb_release -ds 2>/dev/null || echo "Ubuntu $DISTRO_VERSION")

    print_info "Current system: $current_version"

    # Check if do-release-upgrade is available
    if ! command -v do-release-upgrade &>/dev/null; then
        print_warning "do-release-upgrade not found - installing ubuntu-release-upgrader-core"
        step "Installing ubuntu-release-upgrader-core" pkg_install ubuntu-release-upgrader-core || {
            print_error "Failed to install ubuntu-release-upgrader-core"
            print_info "Install manually with: sudo apt install ubuntu-release-upgrader-core"
            exit 1
        }
    fi

    step_start "Checking for Ubuntu distribution upgrades"

    # Run do-release-upgrade in check mode
    # Capture both stdout and the exit behavior
    local check_output
    check_output=$(do-release-upgrade -c 2>&1) || true

    step_end

    # Check if a new release was found
    # do-release-upgrade -c prints "New release 'XX.XX' available" when upgrade exists
    # and "No new release found" when current
    if echo "$check_output" | grep -qi "new release.*available"; then
        # Extract the new version from the output
        local new_version
        new_version=$(echo "$check_output" | grep -oP "New release '\K[^']+")

        print_warning "Ubuntu distribution upgrade available: $new_version"
        echo ""
        echo -e "  ${CYAN}Upgrade details:${NC}"
        echo "$check_output" | sed 's/^/    /'
        echo ""
        echo -e "  ${YELLOW}To upgrade to $new_version, run:${NC}"
        echo -e "    ${BOLD}sudo do-release-upgrade${NC}"
        echo ""
        echo -e "  ${BLUE}For LTS-to-LTS upgrades only, run:${NC}"
        echo -e "    ${BOLD}sudo do-release-upgrade -m desktop${NC}"
        echo ""
        echo -e "  ${BLUE}Note:${NC} Distribution upgrades require interactive confirmation"
        echo -e "  and typically require a reboot afterward."

        exit 1
    fi

    # No new release found
    print_success "System is on the latest available Ubuntu release"
    exit 0
}

require_sudo "Check Updates" check_distro_upgrade
