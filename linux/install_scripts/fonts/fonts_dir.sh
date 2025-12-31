#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Create fonts directory

step "Creating fonts directory" mkdir -p ~/.local/share/fonts

