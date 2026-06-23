#!/bin/bash
# @name: TeX Live
# @description: Full TeX Live distribution (~8GB)
# @depends: bootstrap.sh
# @requires: sudo
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# See: https://www.tug.org/texlive/quickinstall.html

install_texlive() {
    # TeX Live's installer profile uses GNU-triple arch naming (x86_64 / aarch64).
    # $ARCH is pre-validated to x86_64|arm64 in _common.sh.
    local binary_arch
    binary_arch="binary_$(arch_gnu)-linux"

    local tmpdir
    tmpdir=$(mktemp -d) || return 1

    (
        cd "$tmpdir" || exit 1

        fetch -fL -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz || exit 1
        zcat < install-tl-unx.tar.gz | tar xf - || exit 1

        local install_dir
        install_dir=$(find . -maxdepth 1 -type d -name 'install-tl-*' | head -1)
        [ -n "$install_dir" ] && [ -d "$install_dir" ] || { echo "TexLive installer directory not found" >&2; exit 1; }
        cd "$install_dir" || exit 1

        local tl_year
        tl_year=$(perl ./install-tl --version 2>&1 | sed -n 's/.*version \([0-9]\{4\}\).*/\1/p')
        [ -n "$tl_year" ] || { echo "Could not determine TeX Live release year from installer; check that install-tl is valid" >&2; exit 1; }

        local profile_file="$tmpdir/texlive.profile"
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

        print_warning "TeX Live full installation may take 30+ minutes..."
        sudo -n perl ./install-tl --profile="$profile_file"
    )
    local install_rc=$?
    rm -rf "$tmpdir"
    [ $install_rc -ne 0 ] && return 1

    # Transfer ownership so tlmgr works without sudo (sudo may not have tlmgr
    # in PATH). PATH lookup for the new install is handled by .shell_common,
    # which auto-detects /usr/local/texlive/$year/bin/$arch on shell startup;
    # we deliberately do NOT append to .bashrc/.profile/.zprofile here because
    # those would either be no-ops (if dotfiles.sh has already symlinked the
    # files) or get clobbered when dotfiles.sh runs later in the orchestrator.
    local year
    year=$(ls /usr/local/texlive/ 2>/dev/null | grep -E '^[0-9]{4}$' | sort -n | tail -1)
    if [ -n "$year" ]; then
        sudo -n chown -R "$(id -un):$(id -gn)" "/usr/local/texlive/${year}/"
    fi
}

ensure_command "TeX Live" pdflatex install_texlive sudo

