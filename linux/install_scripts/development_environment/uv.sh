#!/bin/bash
# @name: uv
# @description: Fast Python package and project manager from Astral
# @depends: core_packages.sh
# @parallel: true
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

ensure_command "uv" uv install_uv

# Ensure ~/.local/bin is in PATH (needed after fresh install)
[[ -d "$HOME/.local/bin" && ! "$PATH" =~ "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Update to latest version
step "Updating uv to latest version" uv self update
