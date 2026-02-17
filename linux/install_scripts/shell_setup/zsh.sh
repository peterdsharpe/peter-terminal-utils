#!/bin/bash
# @name: zsh
# @description: Powerful shell with advanced features and plugins
# @depends: bootstrap.sh, build_tools.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_zsh_from_source() {
    # Check for required build tools
    if ! command -v gcc &>/dev/null || ! command -v make &>/dev/null; then
        echo "Missing build tools (gcc, make) - cannot compile zsh from source" >&2
        return 1
    fi
    
    # Create install directory
    mkdir -p "$HOME/local" || return 1
    
    # Fetch latest version from zsh.org
    local version tmpdir oldpwd
    version=$(curl -sL https://www.zsh.org/pub/ \
        | grep -oP 'zsh-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=\.tar\.xz")' \
        | sort -V | tail -1) || return 1
    [ -n "$version" ] || { echo "Could not determine latest zsh version" >&2; return 1; }
    
    # Download and extract to tmpdir
    tmpdir=$(mktemp -d) || return 1
    echo "Building zsh $version in $tmpdir ..."
    curl -Lo "$tmpdir/zsh.tar.xz" "https://www.zsh.org/pub/zsh-${version}.tar.xz" || { rm -rf "$tmpdir"; return 1; }
    tar xf "$tmpdir/zsh.tar.xz" -C "$tmpdir" || { rm -rf "$tmpdir"; return 1; }
    
    # Configure, build, install to ~/local
    oldpwd=$PWD
    cd "$tmpdir/zsh-${version}" || { rm -rf "$tmpdir"; return 1; }
    ./configure --prefix="$HOME/local" || { cd "$oldpwd"; rm -rf "$tmpdir"; return 1; }
    make -j"$(nproc)" || { cd "$oldpwd"; rm -rf "$tmpdir"; return 1; }
    make install || { cd "$oldpwd"; rm -rf "$tmpdir"; return 1; }
    
    # Cleanup
    cd "$oldpwd"
    rm -rf "$tmpdir"
    echo "zsh $version installed to $HOME/local/bin/zsh"
}

if command -v zsh &>/dev/null || [ -x "$HOME/local/bin/zsh" ]; then
    print_skip "zsh already installed"
elif [[ "$HAS_SUDO" == true ]]; then
    # zsh should already be installed via apt in System Packages section
    print_warning "zsh not found - should have been installed via apt"
else
    # Build from source for sudo-less install
    if command -v gcc &>/dev/null && command -v make &>/dev/null; then
        step "Building zsh from source (no sudo)" install_zsh_from_source
    else
        print_skip "zsh (requires build tools: gcc, make)"
    fi
fi

# Ensure ~/local/bin is in PATH for this script session (needed for oh-my-zsh to find zsh)
if [ -d "$HOME/local/bin" ] && [[ ":$PATH:" != *":$HOME/local/bin:"* ]]; then
    export PATH="$HOME/local/bin:$PATH"
fi

### Add ~/local/bin to .bashrc PATH (for sudo-less installs to be discoverable)
### Skips if .bashrc is a symlink (managed by dotfiles - .shell_common handles this path)
add_local_to_bashrc_path() {
    local bashrc="$HOME/.bashrc"
    if [ -L "$bashrc" ]; then
        return 0  # Managed by dotfiles; .shell_common includes ~/local/bin
    fi
    local path_line='export PATH="$HOME/local/bin:$PATH"'
    if [ -f "$bashrc" ] && ! grep -qF 'HOME/local/bin' "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# Added by peter-terminal-utils setup - user-local binaries" >> "$bashrc"
        echo "$path_line" >> "$bashrc"
    fi
}

if [[ "$HAS_SUDO" == false ]] && [ -d "$HOME/local/bin" ]; then
    step "Adding ~/local/bin to .bashrc PATH" add_local_to_bashrc_path
fi
