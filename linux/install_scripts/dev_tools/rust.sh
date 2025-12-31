#!/bin/bash
# @name: Rust
# @description: Rust programming language via rustup
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

ensure_command "Rust" rustup install_rust

