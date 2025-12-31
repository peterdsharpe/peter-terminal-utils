#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Create ~/.local/bin directory (needed for user-local tool installs)

step "Creating ~/.local/bin directory" mkdir -p "$HOME/.local/bin"

