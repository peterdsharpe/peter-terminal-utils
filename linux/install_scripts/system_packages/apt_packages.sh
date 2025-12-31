#!/bin/bash
# @name: System Packages
# @description: Shells, editors, build tools, networking via apt
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_system_packages() {
    # Core packages (always installed)
    local packages=(
        # Shell & editors
        zsh vim neovim tmux
        # Version control
        git git-lfs
        # Build tools
        build-essential
        # CLI utilities (tools with dedicated GitHub scripts are installed there for newer versions)
        tree ncdu jq cloc pv
        # Network
        curl wget net-tools openssh-server mtr
        # VPN & firewall
        openvpn wireguard ufw
        # File transfer & sync
        rsync sshfs rclone
        # Compression
        unzip zip p7zip-full zstd unrar
        # System monitoring
        htop nvtop powertop lm-sensors
        # Document processing
        pandoc
    )

    # GUI packages (only if not headless)
    if [[ "$HEADLESS" == "N" ]]; then
        packages+=(
            nemo
            gnome-shell-extension-manager gnome-tweaks
            vlc dconf-editor
        )
    fi

    step_start "Installing system packages"
    run sudo apt-get update -qq
    run sudo apt-get upgrade -yq
    run sudo apt-get install -yq "${packages[@]}"
    step_end
}

require_sudo "System packages" install_system_packages

