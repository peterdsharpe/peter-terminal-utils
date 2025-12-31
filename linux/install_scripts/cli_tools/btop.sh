#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install btop - visually polished system monitor with mouse support

install_btop() {
    local version btop_arch tmpdir
    version=$(github_latest_version "aristocratos/btop") || return 1
    case "$ARCH" in
        x86_64) btop_arch="x86_64-linux-musl" ;;
        arm64) btop_arch="aarch64-linux-musl" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/btop.tbz" "https://github.com/aristocratos/btop/releases/download/v${version}/btop-${btop_arch}.tbz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/btop.tbz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/btop/bin/btop" "$HOME/.local/bin/btop" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

ensure_command "btop" btop install_btop

