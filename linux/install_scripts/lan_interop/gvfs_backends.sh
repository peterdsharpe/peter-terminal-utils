#!/bin/bash
# @name: GVFS Backends
# @description: Install GVFS backends for remote filesystem browsing in Nemo/Nautilus
# @requires: sudo
# @depends: gnome_packages.sh
# @headless: skip
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "GVFS backends"

###############################################################################
### Install GVFS backends for remote filesystem access
###############################################################################
# gvfs-backends provides SFTP, FTP, WebDAV, and other remote filesystem support
# for GTK file managers like Nemo and Nautilus.
#
# After installation, you can:
#   - Use File > Connect to Server in Nemo
#   - Type sftp://user@hostname.local in the location bar (Ctrl+L)
#   - Browse remote filesystems with drag-and-drop support

install_gvfs_backends() {
    local packages=(
        gvfs-backends    # SFTP, FTP, WebDAV, SMB, etc.
    )
    
    # On Ubuntu 24.04+, SMB support is built into gvfs-backends.
    # On older systems or other distros, a separate package may be needed.
    case "$PKG_MANAGER" in
        dnf)
            # Fedora has separate gvfs-smb package
            packages+=(gvfs-smb)
            ;;
        pacman)
            # Arch has separate gvfs-smb package
            packages+=(gvfs-smb)
            ;;
        # apt: gvfs-backends includes SMB support (no separate package)
    esac

    step_start "Installing GVFS backends for remote filesystem browsing"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end
    
    print_info "Nemo can now browse remote filesystems via SFTP"
    print_info "Use Ctrl+L and enter: sftp://user@hostname.local"
    
    return "$(step_result)"
}

require_sudo "GVFS backends" install_gvfs_backends
