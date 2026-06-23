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
    # croc's official installer detects OS/arch and installs to /usr/local/bin
    # (with sudo) or ~/.local/bin. Run in a subshell so the temp-file EXIT trap
    # is scoped to this install only.
    (
        local tmp_script
        tmp_script=$(mktemp) || exit 1
        trap 'rm -f "$tmp_script"' EXIT

        step_start "Installing croc file transfer tool"
        run fetch -fsSL "https://getcroc.schollz.com" -o "$tmp_script"
        run bash "$tmp_script"
        step_end

        local result
        result=$(step_result)
        [[ "$result" -eq 0 ]] && print_info "Usage: croc send <file>  |  croc <code-phrase>"
        exit "$result"
    )
}

# Version gate via the shared helper (replaces a hand-rolled copy of it).
needs_github_update "schollz/croc" "croc" || exit 0
install_croc
