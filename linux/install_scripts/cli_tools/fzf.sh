#!/bin/bash
# @name: fzf
# @description: Command-line fuzzy finder for files, history, and more
# @repo: junegunn/fzf
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Clone or update fzf repo
ensure_git_repo "https://github.com/junegunn/fzf.git" "$HOME/.fzf" "fzf"

# Build and install binary after clone/update
step "Building fzf binary" "$HOME/.fzf/install" --bin

# Symlink to ~/.local/bin
mkdir -p "$HOME/.local/bin"
step "Installing fzf to ~/.local/bin" install -m 755 "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"

