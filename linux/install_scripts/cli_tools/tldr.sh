#!/bin/bash
# @name: tldr
# @description: Simplified, community-driven man pages (tealdeer Rust client)
# @repo: tealdeer-rs/tealdeer
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# tealdeer releases raw binaries (not tarballs), so we use custom install logic
install_tealdeer() {
    local repo="tealdeer-rs/tealdeer"
    local version arch_suffix binary_url

    version=$(github_latest_version "$repo") || return 1

    case "$ARCH" in
        x86_64) arch_suffix="linux-x86_64-musl" ;;
        arm64)  arch_suffix="linux-aarch64-musl" ;;
        *)      echo "Unsupported architecture: $ARCH" >&2; return 1 ;;
    esac

    binary_url="https://github.com/$repo/releases/download/v${version}/tealdeer-${arch_suffix}"

    mkdir -p "$HOME/.local/bin"
    curl -fsSL -o "$HOME/.local/bin/tldr" "$binary_url" || return 1
    chmod +x "$HOME/.local/bin/tldr"

    # Download the tldr page cache
    "$HOME/.local/bin/tldr" --update
}

ensure_command "tldr" tldr "install_tealdeer"
