#!/bin/bash
# @name: neovim
# @description: Hyperextensible Vim-based text editor
# @repo: neovim/neovim
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="neovim/neovim"

# Neovim installs to ~/local/nvim with symlink to ~/.local/bin/nvim
# (custom install path, can't use ensure_github_tool)
install_neovim() {
    local version nvim_arch nvim_dir tmpdir
    version=$(github_latest_version "$REPO") || return 1
    case "$ARCH" in
        x86_64) nvim_arch="x86_64"; nvim_dir="nvim-linux-x86_64" ;;
        arm64) nvim_arch="arm64"; nvim_dir="nvim-linux-arm64" ;;
    esac
    mkdir -p "$HOME/local" || return 1
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/nvim.tar.gz" "https://github.com/$REPO/releases/download/v${version}/nvim-linux-${nvim_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/nvim.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$HOME/local/nvim"
    mv "$tmpdir/$nvim_dir" "$HOME/local/nvim" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/local/nvim/bin/nvim" "$HOME/.local/bin/nvim" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

# Check version and install/update if needed
needs_github_update "$REPO" "neovim" "nvim" || exit 0
step "Installing neovim" install_neovim

