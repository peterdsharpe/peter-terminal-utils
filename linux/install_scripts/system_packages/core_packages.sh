#!/bin/bash
# @name: Core Packages
# @description: Essential bootstrap packages (git, curl, build tools, compression)
# @requires: sudo
# @parallel: false
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_core_packages() {
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

    step_start "Updating package manager"
    run pkg_update
    step_end

    step_start "Installing core packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end

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

require_sudo "Core packages" install_core_packages
