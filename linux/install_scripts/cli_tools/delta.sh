#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install delta (better git diffs)

install_delta() {
    local version delta_arch tmpdir
    version=$(github_latest_version "dandavison/delta") || return 1
    case "$ARCH" in
        x86_64) delta_arch="x86_64-unknown-linux-musl" ;;
        arm64) delta_arch="aarch64-unknown-linux-gnu" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/delta.tar.gz" "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-${delta_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/delta.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/delta-${version}-${delta_arch}/delta" "$HOME/.local/bin/delta" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

ensure_command "delta" delta install_delta

