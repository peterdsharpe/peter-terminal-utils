#!/bin/bash
# @name: SSH Service
# @description: Enable sshd and allow through ufw firewall
# @depends: network_packages.sh
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

configure_ssh_service() {
    step "Enabling SSH service (starts at boot)" sudo systemctl enable --now ssh
    
    # If ufw firewall is active, allow SSH connections
    if sudo ufw status 2>/dev/null | grep -q "active"; then
        step "Allowing SSH through firewall" sudo ufw allow ssh
    fi
}

require_sudo "SSH service" configure_ssh_service

