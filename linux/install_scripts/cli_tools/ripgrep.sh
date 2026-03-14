#!/bin/bash
# @name: ripgrep
# @description: Fast recursive grep alternative with gitignore support
# @repo: BurntSushi/ripgrep
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_github_tool "BurntSushi/ripgrep" "ripgrep" "rg"
