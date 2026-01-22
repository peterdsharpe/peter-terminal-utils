#!/bin/bash
# @name: Zed
# @description: High-performance code editor from the creators of Atom
# @depends: bootstrap.sh
# @headless: skip
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Zed"

# Zed install script handles both install and update
if ! command -v zed &>/dev/null; then
    # Zed's installer requires SHELL to be set; ensure it's available
    step "Installing Zed" bash -c 'SHELL="${SHELL:-$(command -v bash)}" curl -f https://zed.dev/install.sh | sh'
else
    print_skip "Zed already installed"
fi
