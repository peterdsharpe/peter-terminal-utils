#!/bin/bash
# @name: Docker
# @description: Container runtime for building and running applications
# @requires: sudo
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_docker() {
    curl -fsSL https://get.docker.com | sh || return 1
    sudo usermod -aG docker "$USER"
}

ensure_command "Docker" docker install_docker sudo

# Show warning if user not yet in docker group (requires logout/login to take effect)
if [[ "$HAS_SUDO" == true ]] && ! groups | grep -q docker; then
    print_warning "Log out and back in to use docker without sudo"
fi
