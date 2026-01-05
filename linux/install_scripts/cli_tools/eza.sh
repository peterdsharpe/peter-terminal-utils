#!/bin/bash
# @name: eza
# @description: Modern replacement for ls with colors and icons
# @repo: eza-community/eza
# @depends: core_packages.sh
# @parallel: true
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# strip_components=0: eza release has binary at archive root (flat archive)
ensure_command "eza" eza "install_github_binary eza-community/eza eza eza 0"
