#!/bin/bash
# @name: cloc
# @description: Count lines of code in source files
# @repo: AlDanial/cloc
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_install_cloc() {
    local version="$1"
    local url="https://github.com/AlDanial/cloc/releases/download/v${version}/cloc-${version}.pl"
    local dest="$HOME/.local/bin/cloc"
    fetch -fsSL "$url" -o "$dest" && chmod +x "$dest"
}

latest=$(github_latest_version "AlDanial/cloc") || exit 1

if command -v cloc &>/dev/null; then
    installed=$(cloc --version 2>/dev/null | head -1)
    if [[ "$installed" == "$latest" ]]; then
        print_skip "cloc at latest ($installed)"
    else
        print_info "cloc: $installed -> $latest"
        step "Updating cloc" _install_cloc "$latest"
    fi
else
    step "Installing cloc" _install_cloc "$latest"
fi
