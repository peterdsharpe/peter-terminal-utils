#!/bin/bash
# @name: fastfetch
# @description: Fast system information tool (neofetch alternative)
# @repo: fastfetch-cli/fastfetch
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "fastfetch" fastfetch "install_github_binary fastfetch-cli/fastfetch fastfetch"
