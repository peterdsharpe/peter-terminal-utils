#!/bin/bash
# @name: btop
# @description: Resource monitor with mouse support and beautiful UI
# @repo: aristocratos/btop
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "btop" btop "install_github_binary aristocratos/btop btop"
