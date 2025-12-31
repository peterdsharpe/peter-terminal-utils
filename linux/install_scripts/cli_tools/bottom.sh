#!/bin/bash
# @name: bottom
# @description: System/process monitor with GPU graphs (btm)
# @repo: ClementTsang/bottom
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "bottom" btm "install_github_binary ClementTsang/bottom bottom btm 0"
