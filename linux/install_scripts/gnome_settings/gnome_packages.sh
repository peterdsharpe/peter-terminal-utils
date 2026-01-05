#!/bin/bash
# @name: GNOME Packages
# @description: GNOME desktop applications and tools
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "GNOME packages"
skip_if_not_gnome "GNOME packages"

install_gnome_packages() {
    local packages=(
        vlc           # Media player
        dconf-editor  # GNOME settings editor
        nemo          # File manager (better than Nautilus)
    )

    # Packages requiring name mapping
    local mapped_packages=(
        gnome-shell-extension-manager
        gnome-tweaks
    )

    step_start "Installing GNOME packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end

    step_start "Installing GNOME tools"
    local mapped_list=""
    for pkg in "${mapped_packages[@]}"; do
        mapped_list+=" $(pkg_name "$pkg")"
    done
    # shellcheck disable=SC2086
    run pkg_install $mapped_list
    step_end
}

require_sudo "GNOME packages" install_gnome_packages
