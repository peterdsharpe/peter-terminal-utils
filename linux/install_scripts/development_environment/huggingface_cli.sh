#!/bin/bash
# @name: Hugging Face CLI
# @description: CLI for downloading/uploading models from Hugging Face Hub
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_hf_cli() {
    # Official standalone installer from https://huggingface.co/docs/huggingface_hub/en/guides/cli
    curl -LsSf https://hf.co/cli/install.sh | bash
}

ensure_command "Hugging Face CLI" hf install_hf_cli

# Remind user to authenticate if not already logged in
if command -v hf &>/dev/null && ! hf auth whoami &>/dev/null 2>&1; then
    print_info "Run 'hf auth login' to authenticate with Hugging Face Hub"
fi
