#!/bin/bash
# @name: Git User
# @description: Set git user.name and user.email
# @depends: core_packages.sh
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

step_start "Configuring git user"
run git config --global user.name "$GIT_NAME"
run git config --global user.email "$GIT_EMAIL"
step_end
