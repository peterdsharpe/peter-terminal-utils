#!/bin/bash
# @name: Git Settings
# @description: Aliases, git-lfs, merge/rebase configuration
# @depends: bootstrap.sh
# @locks: gitconfig
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

step_start "Configuring git"
run git config --global init.defaultBranch main
run git config --global pull.rebase false
if command -v nvim &>/dev/null; then
    run git config --global core.editor "nvim"
fi
run git config --global push.autoSetupRemote true
run git config --global fetch.prune true
# Aliases
run git config --global alias.st status
run git config --global alias.co checkout
run git config --global alias.br branch
run git config --global alias.lg "log --oneline --graph --decorate"
run git config --global alias.amend "commit --amend --no-edit"
run git config --global alias.last "log -1 HEAD --stat"
# Better merge/rebase defaults
run git config --global merge.conflictstyle diff3
run git config --global rebase.autoStash true
# Initialize git-lfs (only needed once per user)
run git lfs install
step_end

