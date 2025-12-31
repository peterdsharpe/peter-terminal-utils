#!/bin/bash
# @name: delta
# @description: Syntax-highlighting pager for git, diff, and grep output
# @repo: dandavison/delta
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "delta" delta "install_github_binary dandavison/delta delta"
