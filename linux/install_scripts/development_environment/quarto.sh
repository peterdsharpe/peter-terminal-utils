#!/bin/bash
# @name: quarto
# @description: Quarto open-source scientific and technical publishing system
# @repo: quarto-dev/quarto-cli
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="quarto-dev/quarto-cli"

# Quarto ships as a directory tree (bin/quarto launcher + bundled deno/pandoc/
# typst + share/), not a single binary, so ensure_github_tool can't be used.
# Install the whole tree to ~/local/quarto and symlink the launcher into
# ~/.local/bin (the launcher resolves symlinks to locate its support files).
install_quarto() {
    local version quarto_arch tmpdir url
    version=$(github_latest_version "$REPO") || return 1
    case "$ARCH" in
        x86_64) quarto_arch="amd64" ;;
        arm64)  quarto_arch="arm64" ;;
    esac
    url="https://github.com/$REPO/releases/download/v${version}/quarto-${version}-linux-${quarto_arch}.tar.gz"

    mkdir -p "$HOME/local" || return 1
    tmpdir=$(mktemp -d) || return 1
    fetch -fSL -o "$tmpdir/quarto.tar.gz" "$url" || {
        echo "Failed to download Quarto $version from $url (check network, or that a linux-$quarto_arch asset exists for this release)" >&2
        rm -rf "$tmpdir"; return 1
    }
    tar xf "$tmpdir/quarto.tar.gz" -C "$tmpdir" || {
        echo "Failed to extract $tmpdir/quarto.tar.gz (corrupt or partial download?)" >&2
        rm -rf "$tmpdir"; return 1
    }
    rm -rf "$HOME/local/quarto"
    mv "$tmpdir/quarto-${version}" "$HOME/local/quarto" || { rm -rf "$tmpdir"; return 1; }
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/local/quarto/bin/quarto" "$HOME/.local/bin/quarto" || { rm -rf "$tmpdir"; return 1; }
    rm -rf "$tmpdir"
}

needs_github_update "$REPO" "quarto" "quarto" || exit 0
step "Installing quarto" install_quarto
