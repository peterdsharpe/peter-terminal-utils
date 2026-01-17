#!/bin/bash
# @name: Zed
# @description: High-performance code editor from the creators of Atom
# @depends: bootstrap.sh
# @headless: skip
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Zed"

# WSL uses Zed installed on Windows host - don't install Linux version
if is_wsl; then
    print_skip "Zed (use Windows installation in WSL)"
    exit 0
fi

# Zed install script handles both install and update
if ! command -v zed &>/dev/null; then
    # Zed's installer requires SHELL to be set; ensure it's available
    step "Installing Zed" bash -c 'SHELL="${SHELL:-$(command -v bash)}" curl -f https://zed.dev/install.sh | sh'
else
    print_skip "Zed already installed"
fi
