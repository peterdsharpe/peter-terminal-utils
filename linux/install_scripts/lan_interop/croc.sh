#!/bin/bash
# @name: Croc File Transfer
# @description: Install croc for secure ad-hoc file transfers between computers
# @requires: sudo
# @depends: bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

###############################################################################
### Install croc - secure file transfer tool
###############################################################################
# croc is a modern file transfer tool that uses:
#   - PAKE (Password Authenticated Key Exchange) for end-to-end encryption
#   - Relay servers (or direct LAN transfer when possible)
#   - Simple 3-word code phrases for transfers
#
# Usage:
#   Sender:   croc send file.txt
#   Receiver: croc <code-phrase>
#
# On LAN, croc automatically detects local peers for direct transfer.

install_croc() {
    # Check if already installed and up-to-date
    if command -v croc &>/dev/null; then
        local installed latest
        installed=$(croc --version 2>&1 | grep -oP 'v?\d+\.\d+\.\d+' | head -1)
        installed="${installed#v}"
        latest=$(github_latest_version "schollz/croc") || {
            print_warning "Cannot check croc version (network?)"
            print_skip "croc already installed"
            return 0
        }
        
        if [[ -n "$installed" ]]; then
            semver_compare "$installed" "$latest"
            case $? in
                0) print_skip "croc at latest ($installed)"; return 0 ;;
                2) print_skip "croc newer than release ($installed > $latest)"; return 0 ;;
                1) print_info "croc: $installed -> $latest" ;;
            esac
        fi
    fi

    # croc provides an install script that handles architecture detection
    # and installs to /usr/local/bin (requires sudo) or ~/.local/bin
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    # Download and run the official install script
    # The script detects OS/arch and downloads the appropriate binary
    local tmp_script
    tmp_script=$(mktemp)

    step_start "Installing croc file transfer tool"
    run fetch -fsSL "https://getcroc.schollz.com" -o "$tmp_script"
    run bash "$tmp_script"
    step_end
    local result=$?
    rm -f "$tmp_script"

    if [[ $result -eq 0 ]]; then
        print_info "Usage: croc send <file>  |  croc <code-phrase>"
    fi
    return $result
}

install_croc
