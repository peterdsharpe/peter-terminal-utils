#!/bin/bash
# @name: delta
# @description: Syntax-highlighting pager for git, diff, and grep output
# @repo: dandavison/delta
# @depends: core_packages.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "delta" delta "install_github_binary dandavison/delta delta"

# Configure git to use delta as the pager (only if delta is now available)
if command -v delta &>/dev/null; then
    step_start "Configuring git to use delta"
    run git config --global core.pager delta
    run git config --global interactive.diffFilter 'delta --color-only'
    run git config --global delta.navigate true
    run git config --global delta.side-by-side true
    step_end
fi
