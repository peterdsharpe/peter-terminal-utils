#!/bin/bash
# @name: Cursor
# @description: Cursor AI code editor CLI
# @depends: core_packages.sh
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_cursor() {
    curl -fsSL https://cursor.com/install | bash
}

ensure_command "Cursor CLI" cursor-agent install_cursor

