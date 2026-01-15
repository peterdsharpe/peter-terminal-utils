#!/bin/bash
# @name: System Upgrade
# @description: Upgrade all system packages to latest versions
# @requires: sudo
# @depends: bootstrap.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

upgrade_system() {
    step_start "Upgrading system packages"
    run pkg_upgrade
    step_end
}

require_sudo "System Upgrade" upgrade_system
