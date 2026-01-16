#!/bin/bash
# @name: tldr
# @description: Simplified, community-driven man pages (tealdeer Rust client)
# @repo: tealdeer-rs/tealdeer
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_command "tldr" tldr "install_github_binary tealdeer-rs/tealdeer tldr"
