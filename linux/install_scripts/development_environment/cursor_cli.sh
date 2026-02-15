#!/bin/bash
# @name: Cursor CLI
# @description: Command-line tools for Cursor AI code editor
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_run_cursor_installer() { fetch -fsSL https://cursor.com/install | bash; }

# Cursor install script handles both install and update
if ! command -v cursor-agent &>/dev/null; then
    step "Installing Cursor CLI" _run_cursor_installer
else
    print_skip "Cursor CLI already installed"
fi
