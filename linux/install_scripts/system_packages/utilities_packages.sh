#!/bin/bash
# @name: Utilities Packages
# @description: CLI utilities, monitoring, file sync, document processing
# @requires: sudo
# @parallel: false
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_utilities() {
    local packages=(
        # CLI utilities
        tree         # Directory tree view
        ncdu         # Disk usage analyzer
        cloc         # Count lines of code
        pv           # Pipe viewer (progress bars)
        # System monitoring
        htop         # Process viewer
        nvtop        # GPU monitor
        powertop     # Power consumption
        lm-sensors   # Hardware sensors
        smartmontools # Disk drive health (S.M.A.R.T.)
        # File transfer & sync
        rsync        # Fast file copying
        sshfs        # Mount remote filesystems
        rclone       # Cloud storage sync
        # Document processing
        pandoc       # Universal document converter
    )

    step_start "Installing utility packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end
}

require_sudo "Utility packages" install_utilities
