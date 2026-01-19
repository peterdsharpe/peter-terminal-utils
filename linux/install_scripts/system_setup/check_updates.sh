#!/bin/bash
# @name: Check Updates
# @description: Check for pending Ubuntu package updates (fails if updates are available)
# @requires: sudo
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

### Check Updates ###
# This script checks whether there are pending package updates on Ubuntu.
# It succeeds (exit 0) if no updates are available, and fails (exit 1) if there are
# pending updates. This is useful for CI/CD pipelines or as a pre-deployment check.
#
# When updates are available, the script logs the command to install them, since
# updates cannot be silently applied during an install run (they may require reboots,
# interactive prompts, or significant time).

check_updates() {
    # Only Ubuntu is supported - skip gracefully on other distros
    if ! is_ubuntu; then
        print_skip "Check Updates (Ubuntu only, detected: $DISTRO)"
        exit 0
    fi

    step_start "Checking for pending package updates"

    # Refresh package lists
    run pkg_update

    step_end || {
        print_error "Failed to refresh package lists - cannot check for updates"
        exit 1
    }

    # Get list of upgradable packages
    # apt list --upgradable outputs lines like:
    #   package/version arch [upgradable from: old-version]
    # plus a header line "Listing..." that we filter out
    local upgradable_output upgradable_count
    upgradable_output=$(apt list --upgradable 2>/dev/null | grep -v '^Listing')
    upgradable_count=$(echo -n "$upgradable_output" | grep -c '^' || echo 0)

    # Handle the case where grep returns empty (no matches = count 0)
    if [[ -z "$upgradable_output" ]]; then
        upgradable_count=0
    fi

    if [[ "$upgradable_count" -eq 0 ]]; then
        print_success "System is up to date - no pending updates"
        exit 0
    fi

    # Updates are available - report and fail
    print_warning "Found $upgradable_count pending package update(s)"

    # Show the list of upgradable packages (truncated if too many)
    if [[ "$upgradable_count" -le 20 ]]; then
        echo -e "  ${CYAN}Upgradable packages:${NC}"
        echo "$upgradable_output" | sed 's/^/    /'
    else
        echo -e "  ${CYAN}Upgradable packages (showing first 20 of $upgradable_count):${NC}"
        echo "$upgradable_output" | head -20 | sed 's/^/    /'
        echo -e "    ${YELLOW}... and $((upgradable_count - 20)) more${NC}"
    fi

    # Provide the command to install updates
    echo ""
    echo -e "  ${YELLOW}To install these updates, run:${NC}"
    echo -e "    ${BOLD}sudo apt update && sudo apt upgrade${NC}"
    echo ""
    echo -e "  ${BLUE}For a full upgrade (may remove packages if needed):${NC}"
    echo -e "    ${BOLD}sudo apt update && sudo apt full-upgrade${NC}"

    exit 1
}

require_sudo "Check Updates" check_updates
