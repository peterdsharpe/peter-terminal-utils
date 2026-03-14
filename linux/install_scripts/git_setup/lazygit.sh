#!/bin/bash
# @name: lazygit
# @description: Simple terminal UI for git commands
# @repo: jesseduffield/lazygit
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# strip_components=0: lazygit release has binary at archive root (flat archive)
ensure_github_tool "jesseduffield/lazygit" "lazygit" "lazygit" 0
