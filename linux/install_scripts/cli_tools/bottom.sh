#!/bin/bash
# @name: bottom
# @description: System/process monitor with GPU graphs (btm)
# @repo: ClementTsang/bottom
# @depends: core_packages.sh
# @parallel: true
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# strip_components=0: bottom release has binary at archive root (flat archive)
ensure_command "bottom" btm "install_github_binary ClementTsang/bottom bottom btm 0"
