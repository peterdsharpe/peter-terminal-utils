#!/bin/bash
# @name: IPython Environment
# @description: ipy command with NumPy, Matplotlib, and scientific libraries
# @depends: uv.sh, local_bin.sh
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")

step "Syncing ipy Python environment" uv sync --project "$LINUX_DIR/../ipy"

step "Symlinking ipy command" ln -sf "$LINUX_DIR/../ipy/IPy.sh" "$HOME/.local/bin/ipy"

