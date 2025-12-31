#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install lazygit

install_lazygit() {
    local version lazygit_arch tmpdir
    version=$(github_latest_version "jesseduffield/lazygit") || return 1
    case "$ARCH" in
        x86_64) lazygit_arch="x86_64" ;;
        arm64) lazygit_arch="arm64" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${lazygit_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/lazygit.tar.gz" -C "$tmpdir" lazygit || { rm -rf "$tmpdir"; return 1; }
    if [[ "$HAS_SUDO" == true ]]; then
        sudo install "$tmpdir/lazygit" /usr/local/bin || { rm -rf "$tmpdir"; return 1; }
    else
        install -m 755 "$tmpdir/lazygit" "$HOME/.local/bin/lazygit" || { rm -rf "$tmpdir"; return 1; }
    fi
    rm -rf "$tmpdir"
}

ensure_command "lazygit" lazygit install_lazygit

