#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Install uv (Python package manager)

install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

ensure_command "uv" uv install_uv

