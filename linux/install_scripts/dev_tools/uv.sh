#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install uv (Python package manager)

install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

ensure_command "uv" uv install_uv

