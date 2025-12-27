#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Configure SSH service to start at boot

configure_ssh_service() {
    step "Enabling SSH service (starts at boot)" sudo systemctl enable --now ssh
    
    # If ufw firewall is active, allow SSH connections
    if sudo ufw status 2>/dev/null | grep -q "active"; then
        step "Allowing SSH through firewall" sudo ufw allow ssh
    fi
}

require_sudo "SSH service" configure_ssh_service

