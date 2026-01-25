#!/bin/bash
# @name: Croc File Transfer
# @description: Install croc for secure ad-hoc file transfers between computers
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

    step_start "Installing croc file transfer tool"
    
    # croc provides an install script that handles architecture detection
    # and installs to /usr/local/bin (requires sudo) or ~/.local/bin
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    
    # Download and run the official install script
    # The script detects OS/arch and downloads the appropriate binary
    local tmp_script
    tmp_script=$(mktemp)
    
    if curl -fsSL "https://getcroc.schollz.com" -o "$tmp_script"; then
        # Run with INSTALL_DIR to install to user directory (no sudo needed)
        CROC_INSTALL_DIR="$install_dir" bash "$tmp_script"
        local result=$?
        rm -f "$tmp_script"
        
        if [[ $result -eq 0 ]]; then
            step_end
            print_info "Usage: croc send <file>  |  croc <code-phrase>"
            return 0
        fi
    fi
    
    rm -f "$tmp_script"
    step_end
    return 1
}

install_croc
