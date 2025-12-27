#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Create ~/.local/bin directory (needed for user-local tool installs)

step "Creating ~/.local/bin directory" mkdir -p "$HOME/.local/bin"

