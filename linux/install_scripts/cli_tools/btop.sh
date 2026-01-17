#!/bin/bash
# @name: btop
# @description: Resource monitor with mouse support and beautiful UI
# @repo: aristocratos/btop
# @depends: bootstrap.sh, build_tools.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_github_tool "aristocratos/btop" "btop"
