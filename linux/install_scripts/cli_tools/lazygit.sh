#!/bin/bash
# @name: lazygit
# @description: Simple terminal UI for git commands
# @repo: jesseduffield/lazygit
# @depends: core_packages.sh
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# strip_components=0: lazygit release has binary at archive root (flat archive)
ensure_command "lazygit" lazygit "install_github_binary jesseduffield/lazygit lazygit lazygit 0"
