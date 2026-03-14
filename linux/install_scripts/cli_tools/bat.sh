#!/bin/bash
# @name: bat
# @description: cat with syntax highlighting and git integration
# @repo: sharkdp/bat
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_github_tool "sharkdp/bat" "bat"
