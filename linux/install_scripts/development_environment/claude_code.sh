#!/bin/bash
# @name: claude-code
# @description: Anthropic's terminal-based AI coding assistant
# @depends: bootstrap.sh, nodejs.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_run_claude_installer() { fetch -fsSL https://claude.ai/install.sh | bash; }

# Sandboxing dependencies require sudo. Without sudo we still install Claude
# Code itself (sandbox features will be unavailable). bubblewrap+socat are
# packaged differently across distros, so we skip silently if the package
# install fails rather than aborting.
if [[ "${HAS_SUDO:-false}" == true ]] && ! command -v claude &>/dev/null; then
    step "Installing Claude Code sandboxing dependencies" pkg_install bubblewrap socat \
        || print_warning "Sandboxing dependencies unavailable; Claude Code will still work"
fi

step "Installing/updating Claude Code" _run_claude_installer
