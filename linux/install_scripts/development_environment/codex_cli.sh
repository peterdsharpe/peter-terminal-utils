#!/bin/bash
# @name: codex-cli
# @description: OpenAI's terminal-based AI coding agent
# @depends: bootstrap.sh, nodejs.sh
# @requires: sudo
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_codex_cli() {
    if command -v codex &>/dev/null; then
        print_skip "Codex CLI already installed ($(codex --version 2>/dev/null || echo 'unknown version'))"
        return 0
    fi
    step "Installing Codex CLI" sudo -n npm install -g @openai/codex
}

require_sudo "Codex CLI" install_codex_cli
