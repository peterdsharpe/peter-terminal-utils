#!/bin/bash
# @name: SSH Key
# @description: Generate ~/.ssh/id_ed25519 key pair
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

generate_ssh_key() {
    mkdir -p "$HOME/.ssh" || return 1
    chmod 700 "$HOME/.ssh" || return 1
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
}

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    step "Generating SSH key pair" generate_ssh_key
else
    print_skip "SSH key already exists"
fi

