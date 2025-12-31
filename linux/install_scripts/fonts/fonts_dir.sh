#!/bin/bash
# @name: Fonts Directory
# @description: Create ~/.local/share/fonts directory
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

step "Creating fonts directory" mkdir -p ~/.local/share/fonts

