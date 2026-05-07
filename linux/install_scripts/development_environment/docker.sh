#!/bin/bash
# @name: Docker
# @description: Container runtime for building and running applications
# @depends: bootstrap.sh
# @requires: sudo
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_docker() {
    fetch -fsSL https://get.docker.com | sh || return 1
    # Add current user to docker group
    local current_user
    current_user="$(whoami)"
    if getent group docker &>/dev/null; then
        sudo -n usermod -aG docker "$current_user"
    else
        sudo -n groupadd -f docker
        sudo -n usermod -aG docker "$current_user"
    fi
}

setup_docker() {
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

    # NOTE: We deliberately do NOT prune images/containers/build cache here.
    # `docker system prune -af` destroys cached layers and stopped containers
    # that the user may want; running it on every orchestrator pass would
    # silently wipe user state. Run `docker system prune -af` manually if you
    # want to reclaim disk space.
}

require_sudo "Docker" setup_docker
