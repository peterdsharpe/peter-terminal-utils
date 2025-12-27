#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Generate SSH key pair

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

