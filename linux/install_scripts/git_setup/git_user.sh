#!/bin/bash
# @name: Git User Identity
# @description: Set git user.name and user.email globally
# @depends: core_packages.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

step_start "Configuring git user"
run git config --global user.name "$GIT_NAME"
run git config --global user.email "$GIT_EMAIL"
step_end
