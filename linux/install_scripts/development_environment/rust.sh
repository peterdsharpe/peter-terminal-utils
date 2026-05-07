#!/bin/bash
# @name: Rust
# @description: Rust programming language via rustup
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_run_rustup_installer() {
    fetch --proto "=https" --tlsv1.2 -sSfL https://sh.rustup.rs | sh -s -- -y
}

if ! command -v rustup &>/dev/null; then
    step "Installing Rust via rustup" _run_rustup_installer
fi

# Source cargo env to ensure rustup is in PATH (needed after fresh install)
# shellcheck source=/dev/null
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Skip subsequent steps if rustup install failed - avoids "rustup: command not
# found" noise that hides the real failure.
if ! command -v rustup &>/dev/null; then
    print_error "rustup install failed; skipping toolchain update"
    exit 1
fi

step "Updating Rust toolchain" rustup update

if [[ -d "$HOME/.cargo/registry/cache" || -d "$HOME/.cargo/registry/src" ]]; then
    step "Clearing cargo registry cache" rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src"
fi