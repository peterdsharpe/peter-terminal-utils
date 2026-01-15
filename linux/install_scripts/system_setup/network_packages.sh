#!/bin/bash
# @name: Network Packages
# @description: Networking, VPN, and firewall tools
# @requires: sudo
# @depends: bootstrap.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_network_packages() {
    local packages=(
        # Network diagnostics
        net-tools    # ifconfig, netstat, etc.
        mtr          # Traceroute + ping
        openssh-server
        # VPN
        openvpn
        wireguard
    )

    # Firewall (apt uses ufw, Fedora uses firewalld)
    local firewall_pkg=""
    case "$PKG_MANAGER" in
        apt) firewall_pkg="ufw" ;;
        dnf) firewall_pkg="firewalld" ;;
        # pacman/zypper: ufw available but often use iptables directly
    esac

    step_start "Installing network packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end

    if [[ -n "$firewall_pkg" ]]; then
        step_start "Installing firewall"
        run pkg_install "$firewall_pkg"
        step_end
    fi
}

require_sudo "Network packages" install_network_packages
