#!/bin/bash
# @name: Cursor CLI
# @description: Command-line tools for Cursor AI code editor
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_cursor() {
    curl -fsSL https://cursor.com/install | bash
}

ensure_command "Cursor CLI" cursor-agent install_cursor

