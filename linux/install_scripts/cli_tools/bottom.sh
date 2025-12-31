#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install bottom (btm) - modern system monitor with GPU support

install_bottom() {
    local version btm_arch tmpdir
    version=$(github_latest_version "ClementTsang/bottom") || return 1
    case "$ARCH" in
        x86_64) btm_arch="x86_64-unknown-linux-musl" ;;
        arm64) btm_arch="aarch64-unknown-linux-gnu" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/bottom.tar.gz" "https://github.com/ClementTsang/bottom/releases/download/${version}/bottom_${btm_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/bottom.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/btm" "$HOME/.local/bin/btm" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

ensure_command "bottom" btm install_bottom

