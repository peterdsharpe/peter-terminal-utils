#!/bin/bash
# @name: Zed
# @description: High-performance code editor from the creators of Atom
# @depends: bootstrap.sh
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Zed"

# Zed install script handles both install and update
if ! command -v zed &>/dev/null; then
    # Zed's installer requires SHELL to be set; ensure it's available
    _run_zed_installer() {
        export SHELL="${SHELL:-$(command -v bash)}"
        fetch -fsSL https://zed.dev/install.sh | sh
    }
    step "Installing Zed" _run_zed_installer
else
    print_skip "Zed already installed"
fi
