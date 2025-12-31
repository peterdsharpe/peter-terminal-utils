#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Install TeX Live (full distribution - warning: 7+GB, may take 30+ minutes)
# See: https://www.tug.org/texlive/quickinstall.html

install_texlive() {
    local tmpdir year arch_dir texlive_bin
    tmpdir=$(mktemp -d) || return 1
    cd "$tmpdir" || return 1
    
    # Download installer
    curl -L -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz || { cd /; rm -rf "$tmpdir"; return 1; }
    zcat < install-tl-unx.tar.gz | tar xf - || { cd /; rm -rf "$tmpdir"; return 1; }
    cd install-tl-2* || { cd /; rm -rf "$tmpdir"; return 1; }
    
    # Install non-interactively (full scheme by default)
    print_warning "TeX Live installation may take 30+ minutes..."
    sudo perl ./install-tl --no-interaction || { cd /; rm -rf "$tmpdir"; return 1; }
    
    # Cleanup
    cd /
    rm -rf "$tmpdir"
    
    # Determine install path and add to shell profiles
    year=$(ls /usr/local/texlive/ 2>/dev/null | grep -E '^[0-9]{4}$' | sort -n | tail -1)
    if [ -n "$year" ]; then
        case "$ARCH" in
            x86_64) arch_dir="x86_64-linux" ;;
            arm64) arch_dir="aarch64-linux" ;;
        esac
        texlive_bin="/usr/local/texlive/${year}/bin/${arch_dir}"
        if [ -d "$texlive_bin" ]; then
            # Add to .bashrc for bash non-login shells
            if ! grep -q "texlive" "$HOME/.bashrc" 2>/dev/null; then
                echo "" >> "$HOME/.bashrc"
                echo "# TeX Live" >> "$HOME/.bashrc"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.bashrc"
            fi
            # Add to .profile for bash login shells
            if ! grep -q "texlive" "$HOME/.profile" 2>/dev/null; then
                echo "" >> "$HOME/.profile"
                echo "# TeX Live" >> "$HOME/.profile"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.profile"
            fi
            # Add to .zprofile for zsh login shells (zsh doesn't source .profile)
            if ! grep -q "texlive" "$HOME/.zprofile" 2>/dev/null; then
                echo "" >> "$HOME/.zprofile"
                echo "# TeX Live" >> "$HOME/.zprofile"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.zprofile"
            fi
            # Note: .zshrc is managed via dotfiles symlink and has auto-detection built-in
        fi
    fi
}

ensure_command "TeX Live" pdflatex install_texlive sudo

