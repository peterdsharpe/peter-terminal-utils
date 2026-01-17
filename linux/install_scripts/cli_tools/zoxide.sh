#!/bin/bash
# @name: zoxide
# @description: Smarter cd command that learns your habits
# @repo: ajeetdsouza/zoxide
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Zoxide archive is flat (no top-level directory), so strip=0
ensure_github_tool "ajeetdsouza/zoxide" "zoxide" "zoxide" 0

