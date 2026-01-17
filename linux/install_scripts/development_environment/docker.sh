#!/bin/bash
# @name: Docker
# @description: Container runtime for building and running applications
# @depends: bootstrap.sh
# @requires: sudo
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Docker requires sudo for installation
if [[ "${HAS_SUDO:-false}" == false ]]; then
    print_skip "Docker (requires sudo)"
    exit 0
fi

install_docker() {
    curl -fsSL https://get.docker.com | sh || return 1
    # Add current user to docker group
    local current_user
    current_user="$(whoami)"
    if getent group docker &>/dev/null; then
        sudo usermod -aG docker "$current_user"
    else
        sudo groupadd -f docker
        sudo usermod -aG docker "$current_user"
    fi
}

# Install if not present (package manager handles updates via apt/dnf upgrade)
if ! command -v docker &>/dev/null; then
    step "Installing Docker" install_docker
else
    print_skip "Docker already installed"
fi

# Show warning if user not yet in docker group (requires logout/login to take effect)
if ! groups | grep -q docker; then
    print_warning "Log out and back in to use docker without sudo"
fi
