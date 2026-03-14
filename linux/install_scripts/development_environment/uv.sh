#!/bin/bash
# @name: uv
# @description: Fast Python package and project manager from Astral
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Install if not present
if ! command -v uv &>/dev/null; then
    step "Installing uv" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
fi

# Ensure ~/.local/bin is in PATH (needed after fresh install - directory didn't exist when _common.sh ran)
[[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# Always update to latest (uv has built-in self-update)
step "Updating uv to latest version" uv self update

# Clear cache to reclaim disk space
step "Clearing uv cache" uv cache clean
