#!/bin/bash
# @name: fd
# @description: Fast and user-friendly alternative to find
# @repo: sharkdp/fd
# @depends: core_packages.sh
# @parallel: true
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "fd" fd "install_github_binary sharkdp/fd fd"
