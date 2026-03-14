#!/bin/bash
# @name: fastfetch
# @description: Fast system information tool (neofetch alternative)
# @repo: fastfetch-cli/fastfetch
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="fastfetch-cli/fastfetch"

# fastfetch has non-standard archive structure: fastfetch-{arch}/usr/bin/fastfetch
install_fastfetch() {
    local version arch_suffix tarball_url tmpdir

    version=$(github_latest_version "$REPO") || return 1

    case "$ARCH" in
        x86_64) arch_suffix="linux-amd64" ;;
        arm64)  arch_suffix="linux-aarch64" ;;
        *)      echo "Unsupported architecture: $ARCH" >&2; return 1 ;;
    esac

    tarball_url="https://github.com/$REPO/releases/download/${version}/fastfetch-${arch_suffix}.tar.gz"

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    fetch -fsSL -o "$tmpdir/fastfetch.tar.gz" "$tarball_url" || return 1
    tar xzf "$tmpdir/fastfetch.tar.gz" -C "$tmpdir" || return 1

    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmpdir/fastfetch-${arch_suffix}/usr/bin/fastfetch" "$HOME/.local/bin/fastfetch"
}

# Version-aware install: check if update needed
if command -v fastfetch &>/dev/null; then
    installed=$(get_installed_version fastfetch) || installed=""
    latest=$(github_latest_version "$REPO") || {
        print_warning "Cannot check fastfetch version (network?)"
        exit 0
    }

    if [[ -n "$installed" ]]; then
        semver_compare "$installed" "$latest"
        case $? in
            0) print_skip "fastfetch at latest ($installed)"; exit 0 ;;
            2) print_skip "fastfetch newer than release ($installed > $latest)"; exit 0 ;;
            1) print_info "fastfetch: $installed -> $latest" ;;
        esac
    fi
fi

step "Installing fastfetch" install_fastfetch
