#!/bin/bash
# @name: uv
# @description: Fast Python package and project manager from Astral
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_run_uv_installer() { fetch -fsSL https://astral.sh/uv/install.sh | sh; }

ensure_command "uv" uv _run_uv_installer

# Ensure ~/.local/bin is in PATH (needed after fresh install - directory didn't exist when _common.sh ran)
[[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# Skip the update/clean steps if install failed - they would just spam
# "uv: command not found" errors that obscure the real failure.
if ! command -v uv &>/dev/null; then
    print_error "uv install failed; skipping self-update and cache clean"
    exit 1
fi

step "Updating uv to latest version" uv self update
step "Clearing uv cache" uv cache clean
