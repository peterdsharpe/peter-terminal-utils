#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Install fd (find alternative)

install_fd() {
    local version fd_arch tmpdir
    version=$(github_latest_version "sharkdp/fd") || return 1
    case "$ARCH" in
        x86_64) fd_arch="x86_64-unknown-linux-musl" ;;
        arm64) fd_arch="aarch64-unknown-linux-gnu" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/fd.tar.gz" "https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-${fd_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/fd.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/fd-v${version}-${fd_arch}/fd" "$HOME/.local/bin/fd" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

ensure_command "fd" fd install_fd

