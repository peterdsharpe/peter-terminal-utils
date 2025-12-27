#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Install Cursor CLI

install_cursor() {
    curl -fsSL https://cursor.com/install | bash
}

ensure_command "Cursor CLI" cursor-agent install_cursor

