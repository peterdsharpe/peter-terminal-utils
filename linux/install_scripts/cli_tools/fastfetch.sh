#!/bin/bash
# @name: fastfetch
# @description: Fast system information tool (neofetch alternative)
# @repo: fastfetch-cli/fastfetch
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="fastfetch-cli/fastfetch"

# fastfetch nests the binary at fastfetch-{arch}/usr/bin/fastfetch behind a
# non-probable URL, so it keeps a custom installer (can't use ensure_github_tool).
# Its arch dialect (amd64 / aarch64) matches neither arch_deb nor arch_gnu, so
# the mapping stays inline here.
install_fastfetch() {
    local version arch_suffix tarball_url tmpdir

    version=$(github_latest_version "$REPO") || return 1

    case "$ARCH" in
        x86_64) arch_suffix="linux-amd64" ;;
        arm64)  arch_suffix="linux-aarch64" ;;
    esac

    tarball_url="https://github.com/$REPO/releases/download/${version}/fastfetch-${arch_suffix}.tar.gz"

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    fetch -fsSL -o "$tmpdir/fastfetch.tar.gz" "$tarball_url" || return 1
    tar xzf "$tmpdir/fastfetch.tar.gz" -C "$tmpdir" || return 1

    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/fastfetch-${arch_suffix}/usr/bin/fastfetch" "$HOME/.local/bin/fastfetch"
}

# Version gate via the shared helper (replaces a hand-rolled copy of it).
needs_github_update "$REPO" "fastfetch" || exit 0
step "Installing fastfetch" install_fastfetch
