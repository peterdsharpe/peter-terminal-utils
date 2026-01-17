#!/bin/bash
# @name: bottom
# @description: System/process monitor with GPU graphs (btm)
# @repo: ClementTsang/bottom
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# strip_components=0: bottom release has binary at archive root (flat archive)
ensure_github_tool "ClementTsang/bottom" "bottom" "btm" 0
