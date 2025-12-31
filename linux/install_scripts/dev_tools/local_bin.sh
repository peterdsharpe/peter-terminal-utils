#!/bin/bash
# @name: Local Bin
# @description: Create ~/.local/bin for user binaries
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

step "Creating ~/.local/bin directory" mkdir -p "$HOME/.local/bin"

