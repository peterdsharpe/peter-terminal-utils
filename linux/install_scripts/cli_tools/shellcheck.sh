#!/bin/bash
# @name: shellcheck
# @description: Static analysis tool for shell scripts
# @repo: koalaman/shellcheck
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "shellcheck" shellcheck "install_github_binary koalaman/shellcheck shellcheck"
