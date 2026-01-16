#!/bin/bash
# @name: fastfetch
# @description: Fast system information tool (neofetch alternative)
# @repo: fastfetch-cli/fastfetch
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# fastfetch uses non-standard arch naming (linux-amd64 instead of x86_64-unknown-linux-musl)
install_fastfetch() {
    local repo="fastfetch-cli/fastfetch"
    local version arch_suffix tarball_url tmpdir

    version=$(github_latest_version "$repo") || return 1

    case "$ARCH" in
        x86_64) arch_suffix="linux-amd64" ;;
        arm64)  arch_suffix="linux-aarch64" ;;
        *)      echo "Unsupported architecture: $ARCH" >&2; return 1 ;;
    esac

    tarball_url="https://github.com/$repo/releases/download/${version}/fastfetch-${arch_suffix}.tar.gz"

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    curl -fsSL -o "$tmpdir/fastfetch.tar.gz" "$tarball_url" || return 1
    tar xzf "$tmpdir/fastfetch.tar.gz" -C "$tmpdir" || return 1

    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/fastfetch-${arch_suffix}/usr/bin/fastfetch" "$HOME/.local/bin/fastfetch"
}

ensure_command "fastfetch" fastfetch "install_fastfetch"
