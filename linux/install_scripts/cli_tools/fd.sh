#!/bin/bash
# @name: fd
# @description: Fast and user-friendly alternative to find
# @repo: sharkdp/fd
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_github_tool "sharkdp/fd" "fd"
