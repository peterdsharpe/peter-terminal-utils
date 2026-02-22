#!/bin/bash
# @name: nodejs
# @description: Node.js JavaScript runtime and npm package manager
# @requires: sudo
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_nodejs() {
    case "$PKG_MANAGER" in
        apt)
            # NodeSource LTS repo for Debian/Ubuntu
            fetch -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            pkg_install nodejs
            ;;
        dnf)
            # Fedora ships a recent enough Node.js in its repos
            pkg_install nodejs npm
            ;;
        pacman)
            pkg_install nodejs npm
            ;;
        zypper)
            pkg_install nodejs npm
            ;;
        *)
            print_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

if ! command -v node &>/dev/null; then
    step "Installing Node.js and npm" install_nodejs
else
    print_skip "Node.js already installed ($(node -v))"
fi

# Ensure npm is up to date
if command -v npm &>/dev/null; then
    step "Updating npm to latest version" sudo npm install -g npm@latest
fi
