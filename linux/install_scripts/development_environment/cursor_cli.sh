#!/bin/bash
# @name: Cursor CLI
# @description: Command-line tools for Cursor AI code editor
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Cursor install script handles both install and update
if ! command -v cursor-agent &>/dev/null; then
    step "Installing Cursor CLI" bash -c 'curl -fsSL https://cursor.com/install | bash'
else
    print_skip "Cursor CLI already installed"
fi

