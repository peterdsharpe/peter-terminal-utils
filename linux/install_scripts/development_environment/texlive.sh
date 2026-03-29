#!/bin/bash
# @name: TeX Live
# @description: Full TeX Live distribution (~8GB)
# @depends: bootstrap.sh
# @requires: sudo
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# See: https://www.tug.org/texlive/quickinstall.html

install_texlive() {
    local tmpdir year arch_dir texlive_bin install_dir profile_file
    tmpdir=$(mktemp -d) || return 1
    
    # Use subshell to isolate directory changes
    (
        cd "$tmpdir" || exit 1
        
        # Download installer
        curl -fL -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz || exit 1
        zcat < install-tl-unx.tar.gz | tar xf - || exit 1
        
        # Find the extracted directory (handles varying naming conventions)
        install_dir=$(find . -maxdepth 1 -type d -name 'install-tl-*' | head -1)
        [ -n "$install_dir" ] && [ -d "$install_dir" ] || { echo "TexLive installer directory not found" >&2; exit 1; }
        cd "$install_dir" || exit 1
        
        # Detect the TeX Live release year from the installer
        local tl_year
        tl_year=$(perl ./install-tl --version 2>&1 | sed -n 's/.*version \([0-9]\{4\}\).*/\1/p')
        [ -n "$tl_year" ] || { echo "Could not determine TeX Live release year from installer; check that install-tl is valid" >&2; exit 1; }
        
        # Create installation profile to disable GUI apps and documentation
        profile_file="$tmpdir/texlive.profile"
        
        # Determine binary architecture for profile
        local binary_arch
        case "$ARCH" in
            x86_64) binary_arch="binary_x86_64-linux" ;;
            arm64|aarch64) binary_arch="binary_aarch64-linux" ;;
            *) binary_arch="binary_x86_64-linux" ;;  # default fallback
        esac
        
        cat > "$profile_file" << EOF
# TeX Live installation profile
# Installs full scheme without GUI apps, desktop entries, or documentation
selected_scheme scheme-full
TEXDIR /usr/local/texlive/$tl_year
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSCONFIG /usr/local/texlive/$tl_year/texmf-config
TEXMFSYSVAR /usr/local/texlive/$tl_year/texmf-var
$binary_arch 1
instopt_adjustpath 0
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info 0
tlpdbopt_sys_man 0
tlpdbopt_w32_multi_user 1
EOF
        
        # Install non-interactively using profile
        print_warning "TeX Live full installation may take 30+ minutes..."
        sudo perl ./install-tl --profile="$profile_file"
    )
    local install_rc=$?
    rm -rf "$tmpdir"
    [ $install_rc -ne 0 ] && return 1
    
    # Determine install path and add to shell profiles
    year=$(ls /usr/local/texlive/ 2>/dev/null | grep -E '^[0-9]{4}$' | sort -n | tail -1)
    if [ -n "$year" ]; then
        # Transfer ownership so tlmgr works without sudo (sudo may not have tlmgr in PATH)
        sudo chown -R "$(id -un):$(id -gn)" "/usr/local/texlive/${year}/"
        
        case "$ARCH" in
            x86_64) arch_dir="x86_64-linux" ;;
            arm64) arch_dir="aarch64-linux" ;;
        esac
        texlive_bin="/usr/local/texlive/${year}/bin/${arch_dir}"
        if [ -d "$texlive_bin" ]; then
            # Add to .bashrc for bash non-login shells
            # Skip if .bashrc is a symlink (managed by dotfiles with auto-detection)
            if [ ! -L "$HOME/.bashrc" ] && ! grep -q "texlive" "$HOME/.bashrc" 2>/dev/null; then
                echo "" >> "$HOME/.bashrc"
                echo "# TeX Live" >> "$HOME/.bashrc"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.bashrc"
            fi
            # Add to .profile for bash login shells
            if [ ! -L "$HOME/.profile" ] && ! grep -q "texlive" "$HOME/.profile" 2>/dev/null; then
                echo "" >> "$HOME/.profile"
                echo "# TeX Live" >> "$HOME/.profile"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.profile"
            fi
            # Add to .zprofile for zsh login shells (zsh doesn't source .profile)
            if [ ! -L "$HOME/.zprofile" ] && ! grep -q "texlive" "$HOME/.zprofile" 2>/dev/null; then
                echo "" >> "$HOME/.zprofile"
                echo "# TeX Live" >> "$HOME/.zprofile"
                echo "export PATH=\"$texlive_bin:\$PATH\"" >> "$HOME/.zprofile"
            fi
            # Note: .zshrc/.bashrc are managed via dotfiles symlinks with auto-detection
        fi
    fi
}

ensure_command "TeX Live" pdflatex install_texlive sudo

