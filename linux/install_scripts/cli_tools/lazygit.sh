#!/bin/bash
# @name: lazygit
# @description: Simple terminal UI for git commands
# @repo: jesseduffield/lazygit
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "lazygit" lazygit "install_github_binary jesseduffield/lazygit lazygit lazygit 0"
