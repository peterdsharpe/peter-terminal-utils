#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install eza (ls alternative)

install_eza() {
    local version eza_arch tmpdir
    version=$(github_latest_version "eza-community/eza") || return 1
    case "$ARCH" in
        x86_64) eza_arch="x86_64-unknown-linux-musl" ;;
        arm64) eza_arch="aarch64-unknown-linux-gnu" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/eza.tar.gz" "https://github.com/eza-community/eza/releases/download/v${version}/eza_${eza_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/eza.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/eza" "$HOME/.local/bin/eza" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

ensure_command "eza" eza install_eza

