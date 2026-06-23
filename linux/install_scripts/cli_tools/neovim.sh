#!/bin/bash
# @name: neovim
# @description: Hyperextensible Vim-based text editor
# @repo: neovim/neovim
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="neovim/neovim"

# Neovim ships as a directory tree (bin/nvim + share/nvim/runtime) that must
# stay together, so it uses install_github_tree rather than ensure_github_tool.
# Neovim's release naming uses $ARCH (x86_64|arm64) verbatim.
needs_github_update "$REPO" "neovim" "nvim" || exit 0
version=$(github_latest_version "$REPO") || exit 1
step "Installing neovim" install_github_tree "nvim" \
    "https://github.com/$REPO/releases/download/v${version}/nvim-linux-${ARCH}.tar.gz" "bin/nvim"
