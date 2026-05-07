#!/bin/bash
# @name: nodejs
# @description: Node.js JavaScript runtime and npm package manager
# @requires: sudo
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_nodejs() {
    case "$PKG_MANAGER" in
        apt)
            # NodeSource LTS repo for Debian/Ubuntu
            fetch -fsSL https://deb.nodesource.com/setup_lts.x | sudo -n -E bash -
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

### Keep npm current, but only when there's actually a newer version available.
### `sudo npm install -g npm@latest` makes a network round-trip and rebuilds
### symlinks every run; skipping it when versions match saves seconds and
### avoids needless sudo invocations on repeat orchestrator passes.
update_npm_if_needed() {
    local installed latest
    installed=$(npm -v 2>/dev/null) || return 1
    latest=$(npm view npm version 2>/dev/null) || {
        print_warning "Cannot reach npm registry; skipping npm self-update"
        return 0
    }
    semver_compare "$installed" "$latest"
    case $? in
        0) print_skip "npm at latest ($installed)" ;;
        2) print_skip "npm newer than registry ($installed > $latest)" ;;
        1) step "Updating npm $installed -> $latest" sudo -n npm install -g npm@latest ;;
    esac
}

if command -v npm &>/dev/null; then
    update_npm_if_needed
fi
