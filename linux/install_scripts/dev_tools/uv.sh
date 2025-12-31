#!/bin/bash
# @name: uv
# @description: Fast Python package and project manager from Astral
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

ensure_command "uv" uv install_uv

