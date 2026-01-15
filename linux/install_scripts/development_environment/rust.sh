#!/bin/bash
# @name: Rust
# @description: Rust programming language via rustup
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

ensure_command "Rust" rustup install_rust

# Source cargo env to ensure rustup is in PATH (needed after fresh install)
# shellcheck source=/dev/null
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Update Rust toolchain to latest
step "Updating Rust toolchain" rustup update