#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install GitHub CLI (gh)

install_github_cli() {
    if [[ "$HAS_SUDO" == true ]]; then
        # Install via apt repository (preferred for system-wide install)
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || return 1
        sudo apt-get update -qq || return 1
        sudo apt-get install -yq gh
    else
        # Install prebuilt binary to ~/.local/bin
        local version gh_arch tmpdir
        version=$(github_latest_version "cli/cli") || return 1
        case "$ARCH" in
            x86_64) gh_arch="amd64" ;;
            arm64) gh_arch="arm64" ;;
        esac
        tmpdir=$(mktemp -d) || return 1
        curl -fSL -o "$tmpdir/gh.tar.gz" "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${gh_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
        tar xf "$tmpdir/gh.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
        install -m 755 "$tmpdir/gh_${version}_linux_${gh_arch}/bin/gh" "$HOME/.local/bin/gh" || { rm -rf "$tmpdir"; return 1; }
        rm -rf "$tmpdir"
    fi
}

ensure_command "GitHub CLI" gh install_github_cli

