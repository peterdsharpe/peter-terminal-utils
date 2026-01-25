#!/bin/bash
# @name: System Upgrade
# @description: Upgrade all system packages to latest versions
# @requires: sudo
# @depends: bootstrap.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

upgrade_system() {
    step "Upgrading system packages" pkg_upgrade
    step "Removing orphaned packages" pkg_autoremove
    step "Clearing package cache" pkg_clean
}

require_sudo "System Upgrade" upgrade_system
