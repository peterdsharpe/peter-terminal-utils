#!/bin/bash
# @name: gdu
# @description: Fast disk usage analyzer with console interface
# @repo: dundee/gdu
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# gdu's archive contains binary named gdu_linux_{arch} (e.g., gdu_linux_amd64)
# strip_components=0: flat archive; installed_name=gdu: rename from arch-specific name
arch_suffix=$(get_release_arch "gdu")
ensure_github_tool "dundee/gdu" "gdu" "gdu_${arch_suffix}" 0 "gdu"
