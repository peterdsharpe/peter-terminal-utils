#!/bin/bash
# @name: shellcheck
# @description: Static analysis tool for shell scripts
# @repo: koalaman/shellcheck
# @depends: bootstrap.sh, build_tools.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_github_tool "koalaman/shellcheck" "shellcheck"
