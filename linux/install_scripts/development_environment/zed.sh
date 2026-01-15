#!/bin/bash
# @name: Zed
# @description: High-performance code editor from the creators of Atom
# @depends: core_packages.sh
# @parallel: true
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_zed() {
    curl -f https://zed.dev/install.sh | sh
}

ensure_command "Zed" zed install_zed
