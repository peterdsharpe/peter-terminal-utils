#!/bin/bash
# @name: zoxide
# @description: Smarter cd command that learns your habits
# @repo: ajeetdsouza/zoxide
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_zoxide() {
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

ensure_command "zoxide" zoxide install_zoxide

