#!/bin/bash
# @name: eza
# @description: Modern replacement for ls with colors and icons
# @repo: eza-community/eza
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# strip_components=0: eza release has binary at archive root (flat archive)
ensure_github_tool "eza-community/eza" "eza" "eza" 0
