#!/bin/bash
# @name: tldr
# @description: Simplified, community-driven man pages (tealdeer Rust client)
# @repo: tealdeer-rs/tealdeer
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# tealdeer releases raw binaries (not tarballs), use raw download mode
# Binary in release is "tealdeer-linux-{arch}-musl", install as "tldr"
ensure_github_tool "tealdeer-rs/tealdeer" "tealdeer" "tealdeer" 1 "tldr" "raw"

# Update the tldr page cache after install/update
if command -v tldr &>/dev/null; then
    step "Updating tldr page cache" tldr --update
fi
