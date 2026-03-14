#!/bin/bash
# @name: claude-code
# @description: Anthropic's terminal-based AI coding assistant
# @depends: bootstrap.sh, nodejs.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_run_claude_installer() { fetch -fsSL https://claude.ai/install.sh | bash; }

if ! command -v claude &>/dev/null; then
    step "Installing Claude Code sandboxing dependencies" pkg_install bubblewrap socat
fi

# Always run the installer — it handles both fresh installs and updates
step "Installing/updating Claude Code" _run_claude_installer
