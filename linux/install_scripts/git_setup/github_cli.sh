#!/bin/bash
# @name: GitHub CLI
# @description: GitHub's official CLI for managing repos, PRs, and issues
# @repo: cli/cli
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="cli/cli"

install_github_cli_pkg() {
    # Install via package manager (requires sudo)
    case "$PKG_MANAGER" in
        apt)
            # Add GitHub CLI apt repository for latest updates
            fetch -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg || return 1
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || return 1
            pkg_update || return 1
            # shellcheck disable=SC2046
            pkg_install $(pkg_name gh)
            ;;
        dnf|pacman|zypper)
            # These distros have gh in default/community repos
            # shellcheck disable=SC2046
            pkg_install $(pkg_name gh)
            ;;
        *)
            return 1  # Unknown package manager
            ;;
    esac
}

# Skip if already installed (package manager handles updates via upgrade)
if command -v gh &>/dev/null; then
    print_skip "GitHub CLI already installed"
else
    # Try package manager first (with sudo), fall back to binary install
    if [[ "${HAS_SUDO:-false}" == true ]]; then
        step "Installing GitHub CLI" install_github_cli_pkg || \
            step "Installing GitHub CLI (binary)" install_github_binary "$REPO" "gh" "gh" 1 "auto" "gh"
    else
        # No sudo: use binary install with version checking
        step "Installing GitHub CLI" install_github_binary "$REPO" "gh" "gh" 1 "auto" "gh"
    fi
fi

# Remind user to authenticate if not already logged in
if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
    print_info "Run 'gh auth login' to authenticate with GitHub"
fi
