#!/bin/bash
# @name: NVIDIA Driver
# @description: Install proprietary NVIDIA drivers for systems with NVIDIA GPUs
# @requires: sudo
# @headless: skip
# @depends: bootstrap.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "NVIDIA driver"

# WSL uses GPU passthrough from Windows host - installing Linux drivers breaks this
if is_wsl; then
    print_skip "NVIDIA driver (WSL uses host drivers)"
    exit 0
fi

# Check if NVIDIA hardware is present
has_nvidia_gpu() {
    lspci 2>/dev/null | grep -qi 'nvidia'
}

# Check if NVIDIA driver is already working
nvidia_driver_working() {
    command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null
}

install_nvidia_driver() {
    # Skip if no NVIDIA GPU
    if ! has_nvidia_gpu; then
        print_skip "NVIDIA driver (no NVIDIA GPU detected)"
        return 0
    fi
    
    # Skip if already working
    if nvidia_driver_working; then
        print_skip "NVIDIA driver already installed and working"
        return 0
    fi
    
    # ubuntu-drivers is Ubuntu/Debian specific
    if ! command -v ubuntu-drivers &>/dev/null; then
        # Try to install ubuntu-drivers-common on apt-based systems
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            step_start "Installing ubuntu-drivers-common"
            run pkg_install ubuntu-drivers-common
            step_end
        else
            print_skip "NVIDIA driver (ubuntu-drivers not available on $DISTRO)"
            return 0
        fi
    fi
    
    step_start "Installing recommended NVIDIA driver"
    run sudo ubuntu-drivers install
    step_end
    
    print_warn "Reboot required for NVIDIA driver to take effect"
}

require_sudo "NVIDIA driver" install_nvidia_driver
