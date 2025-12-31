#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install bat (cat alternative)

install_bat() {
    local version bat_arch tmpdir
    version=$(github_latest_version "sharkdp/bat") || return 1
    case "$ARCH" in
        x86_64) bat_arch="x86_64-unknown-linux-musl" ;;
        arm64) bat_arch="aarch64-unknown-linux-gnu" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/bat.tar.gz" "https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-${bat_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/bat.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/bat-v${version}-${bat_arch}/bat" "$HOME/.local/bin/bat" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

ensure_command "bat" bat install_bat

