#!/bin/bash
# @name: GitHub CLI
# @description: GitHub's official CLI for managing repos, PRs, and issues
# @repo: cli/cli
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_github_cli_binary() {
    # Install prebuilt binary to ~/.local/bin (works on all distros)
    local version gh_arch tmpdir
    version=$(github_latest_version "cli/cli") || return 1
    case "$ARCH" in
        x86_64) gh_arch="amd64" ;;
        arm64) gh_arch="arm64" ;;
    esac
    tmpdir=$(mktemp -d) || return 1
    curl -fSL -o "$tmpdir/gh.tar.gz" "https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${gh_arch}.tar.gz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/gh.tar.gz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin" || { rm -rf "$tmpdir"; return 1; }
    install -m 755 "$tmpdir/gh_${version}_linux_${gh_arch}/bin/gh" "$HOME/.local/bin/gh" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

install_github_cli() {
    if [[ "$HAS_SUDO" == true ]]; then
        case "$PKG_MANAGER" in
            apt)
                # Install via apt repository
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
                sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || return 1
                sudo apt-get update -qq || return 1
                sudo apt-get install -yq gh
                ;;
            dnf)
                # Fedora has gh in default repos
                sudo dnf install -y gh
                ;;
            pacman)
                # Arch has gh in community repo
                sudo pacman -S --noconfirm github-cli
                ;;
            *)
                # Fall back to binary install
                install_github_cli_binary
                ;;
        esac
    else
        install_github_cli_binary
    fi
}

ensure_command "GitHub CLI" gh install_github_cli

