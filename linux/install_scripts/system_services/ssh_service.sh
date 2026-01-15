#!/bin/bash
# @name: SSH Service
# @description: Enable sshd and allow through ufw firewall
# @depends: network_packages.sh
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

configure_ssh_service() {
    # SSH service name varies by distro: "ssh" on Debian/Ubuntu, "sshd" on Fedora/RHEL/Arch
    local ssh_service
    case "$PKG_MANAGER" in
        apt) ssh_service="ssh" ;;
        dnf|pacman|zypper) ssh_service="sshd" ;;
        *) ssh_service="sshd" ;;  # Fallback to common name
    esac
    
    step "Enabling SSH service (starts at boot)" sudo systemctl enable --now "$ssh_service"
    
    # If ufw firewall is active, allow SSH connections
    if sudo ufw status 2>/dev/null | grep -q "active"; then
        step "Allowing SSH through firewall" sudo ufw allow ssh
    fi
}

require_sudo "SSH service" configure_ssh_service

