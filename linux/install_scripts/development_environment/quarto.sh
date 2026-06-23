#!/bin/bash
# @name: quarto
# @description: Quarto open-source scientific and technical publishing system
# @repo: quarto-dev/quarto-cli
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="quarto-dev/quarto-cli"

# Quarto ships as a directory tree (bin/quarto launcher + bundled deno/pandoc/
# typst + share/) that must stay together, so it uses install_github_tree
# rather than ensure_github_tool.
needs_github_update "$REPO" "quarto" "quarto" || exit 0
version=$(github_latest_version "$REPO") || exit 1
step "Installing quarto" install_github_tree "quarto" \
    "https://github.com/$REPO/releases/download/v${version}/quarto-${version}-linux-$(arch_deb).tar.gz" "bin/quarto"
