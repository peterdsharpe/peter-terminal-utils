#!/bin/bash
# @name: Docker
# @description: Container runtime for building and running applications
# @depends: bootstrap.sh
# @requires: sudo
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_docker() {
    curl -fsSL https://get.docker.com | sh || return 1
    # Wait for docker group to be created (the install script creates it)
    # Then add current user to it
    if getent group docker &>/dev/null; then
        sudo usermod -aG docker "$USER"
    else
        # Group should exist after docker install; if not, create it
        sudo groupadd -f docker
        sudo usermod -aG docker "$USER"
    fi
}

ensure_command "Docker" docker install_docker sudo

# Show warning if user not yet in docker group (requires logout/login to take effect)
if [[ "$HAS_SUDO" == true ]] && ! groups | grep -q docker; then
    print_warning "Log out and back in to use docker without sudo"
fi
