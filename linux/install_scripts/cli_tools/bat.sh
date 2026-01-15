#!/bin/bash
# @name: bat
# @description: cat with syntax highlighting and git integration
# @repo: sharkdp/bat
# @depends: core_packages.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "bat" bat "install_github_binary sharkdp/bat bat"
