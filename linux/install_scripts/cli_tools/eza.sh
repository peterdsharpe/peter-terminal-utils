#!/bin/bash
# @name: eza
# @description: Modern replacement for ls with colors and icons
# @repo: eza-community/eza
# @parallel: true
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "eza" eza "install_github_binary eza-community/eza eza eza 0"
