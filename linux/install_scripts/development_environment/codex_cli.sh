#!/bin/bash
# @name: codex-cli
# @description: OpenAI's terminal-based AI coding agent
# @depends: bootstrap.sh, nodejs.sh
# @requires: sudo
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

if ! command -v codex &>/dev/null; then
    step "Installing Codex CLI" sudo npm install -g @openai/codex
else
    print_skip "Codex CLI already installed ($(codex --version 2>/dev/null || echo 'unknown version'))"
fi
