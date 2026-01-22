#!/bin/bash
# @name: Virt Manager
# @description: Virtual machine manager GUI (requires libvirt/QEMU to be installed separately)
# @depends: bootstrap.sh, flatpak_apps.sh
# @requires: sudo
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Virt Manager"

# WSL: use Windows virtualization tools instead
if is_wsl; then
    print_skip "Virt Manager (use Windows virtualization tools in WSL)"
    exit 0
fi

# Check if already installed (native or flatpak)
if command -v virt-manager &>/dev/null; then
    print_skip "Virt Manager already installed"
    exit 0
fi

if flatpak info org.virt_manager.virt-manager &>/dev/null 2>&1; then
    print_skip "Virt Manager already installed (Flatpak)"
    exit 0
fi

# Install via native package manager, fall back to Flatpak
install_virt_manager() {
    if [[ "$PKG_MANAGER" != "unknown" ]]; then
        step "Installing Virt Manager" pkg_install virt-manager
    else
        # Flatpak fallback for unsupported package managers
        step "Installing Virt Manager via Flatpak" flatpak install -y --user flathub org.virt_manager.virt-manager
    fi
}

require_sudo "Virt Manager" install_virt_manager
