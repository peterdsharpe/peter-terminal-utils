#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install Cursor CLI

install_cursor() {
    curl -fsSL https://cursor.com/install | bash
}

ensure_command "Cursor CLI" cursor-agent install_cursor

