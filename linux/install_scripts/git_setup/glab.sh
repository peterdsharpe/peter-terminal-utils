#!/bin/bash
# @name: GitLab CLI
# @description: GitLab's official CLI for managing repos, MRs, and issues
# @repo: gitlab-org/cli (on GitLab)
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Get latest version from GitLab API (public, no auth required)
gitlab_latest_version() {
    local api_resp version
    api_resp=$(curl -sf --connect-timeout 10 \
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases" | head -c 10000) || {
        echo "Failed to fetch GitLab CLI releases from API" >&2
        return 1
    }
    # Extract first tag_name from JSON array (latest release)
    version=$(echo "$api_resp" | grep -oP '"tag_name"\s*:\s*"v?\K[^"]+' | head -1) || {
        echo "Failed to parse version from GitLab API response" >&2
        return 1
    }
    echo "$version"
}

install_glab_binary() {
    local version glab_arch tmpdir download_url
    version=$(gitlab_latest_version) || return 1

    case "$ARCH" in
        x86_64) glab_arch="amd64" ;;
        arm64)  glab_arch="arm64" ;;
    esac

    tmpdir=$(mktemp -d) || return 1
    download_url="https://gitlab.com/gitlab-org/cli/-/releases/v${version}/downloads/glab_${version}_linux_${glab_arch}.tar.gz"

    curl -fSL -o "$tmpdir/glab.tar.gz" "$download_url" || {
        echo "Failed to download glab from $download_url" >&2
        rm -rf "$tmpdir"
        return 1
    }

    tar xzf "$tmpdir/glab.tar.gz" -C "$tmpdir" || {
        echo "Failed to extract glab archive" >&2
        rm -rf "$tmpdir"
        return 1
    }

    mkdir -p "$HOME/.local/bin" || { rm -rf "$tmpdir"; return 1; }

    # Find the glab binary (may be in bin/ subdirectory or at root)
    local glab_bin
    glab_bin=$(find "$tmpdir" -name "glab" -type f -executable 2>/dev/null | head -1)
    if [[ -z "$glab_bin" ]]; then
        glab_bin=$(find "$tmpdir" -name "glab" -type f 2>/dev/null | head -1)
    fi

    if [[ -z "$glab_bin" ]]; then
        echo "glab binary not found in archive" >&2
        rm -rf "$tmpdir"
        return 1
    fi

    install -m 755 "$glab_bin" "$HOME/.local/bin/glab" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

install_glab_snap() {
    sudo snap install glab
}

install_glab() {
    if [[ "$HAS_SUDO" == true ]] && command -v snap &>/dev/null; then
        install_glab_snap
    else
        install_glab_binary
    fi
}

ensure_command "GitLab CLI" glab install_glab

# Remind user to authenticate if not already logged in
if command -v glab &>/dev/null && ! glab auth status &>/dev/null 2>&1; then
    print_info "Run 'glab auth login' to authenticate with GitLab"
fi
