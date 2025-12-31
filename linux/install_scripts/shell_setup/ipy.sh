#!/bin/bash
# @name: IPy
# @description: Interactive Python with NumPy, Matplotlib, etc.
# @depends: uv.sh
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

LINUX_DIR=$(get_linux_dir)

step "Syncing ipy Python environment" uv sync --project "$LINUX_DIR/../ipy"

step "Symlinking ipy command" ln -sf "$LINUX_DIR/../ipy/IPy.sh" "$HOME/.local/bin/ipy"

