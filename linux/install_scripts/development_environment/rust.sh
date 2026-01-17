#!/bin/bash
# @name: Rust
# @description: Rust programming language via rustup
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Install if not present
if ! command -v rustup &>/dev/null; then
    step "Installing Rust via rustup" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
fi

# Source cargo env to ensure rustup is in PATH (needed after fresh install)
# shellcheck source=/dev/null
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Always update toolchain (rustup has built-in update)
step "Updating Rust toolchain" rustup update