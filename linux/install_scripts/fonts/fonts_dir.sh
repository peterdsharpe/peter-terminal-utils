#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Create fonts directory

step "Creating fonts directory" mkdir -p ~/.local/share/fonts

