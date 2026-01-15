#!/bin/bash
# @name: Bootstrap
# @description: Update repos and install essential packages (git, curl, jq, compression)
# @requires: sudo
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_bootstrap_packages() {
    # Pre-flight check: ensure package manager is in healthy state
    if ! pkg_check_health; then
        return 1
    fi

    local packages=(
        # Version control (many scripts depend on these)
        git git-lfs
        # Downloading (many installers need these)
        curl wget
        # JSON processing (GNOME extension scripts, API parsing)
        jq
        # Compression (font installs, GitHub binary installs need these)
        unzip zip zstd
    )

    step_start "Updating package manager"
    run pkg_update
    step_end

    step_start "Installing bootstrap packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end
}

require_sudo "Bootstrap" install_bootstrap_packages
