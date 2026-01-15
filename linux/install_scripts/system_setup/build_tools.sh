#!/bin/bash
# @name: Build Tools
# @description: Compilers and archive tools (build-essential, p7zip, unrar)
# @requires: sudo
# @depends: bootstrap.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_build_tools() {
    # Packages requiring name mapping
    local mapped_packages=(
        build-essential  # gcc, make, etc. for compiling
        p7zip-full       # 7z support
    )

    # Packages only available on certain distros
    local distro_specific=()
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        distro_specific+=(unrar)  # On Fedora/Arch, use RPM Fusion / AUR
    fi

    step_start "Installing build tools"
    local mapped_list=""
    for pkg in "${mapped_packages[@]}"; do
        mapped_list+=" $(pkg_name "$pkg")"
    done
    # shellcheck disable=SC2086
    run pkg_install $mapped_list
    step_end

    if [[ ${#distro_specific[@]} -gt 0 ]]; then
        step_start "Installing distro-specific packages"
        # shellcheck disable=SC2086
        run pkg_install ${distro_specific[*]}
        step_end
    fi
}

require_sudo "Build Tools" install_build_tools
