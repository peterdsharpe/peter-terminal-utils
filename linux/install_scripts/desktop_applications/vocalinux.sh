#!/bin/bash
# @name: Vocalinux
# @description: Offline voice dictation for Linux (whisper.cpp/VOSK/Whisper)
# @depends: bootstrap.sh
# @requires: sudo
# @locks: pkg
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Vocalinux"

_install_vocalinux() {
    local installer
    installer=$(mktemp) || return 1
    fetch -fsSL "https://raw.githubusercontent.com/jatinkrmalik/vocalinux/main/install.sh" \
        -o "$installer" || { rm -f "$installer"; return 1; }
    bash "$installer" --auto
    local rc=$?
    rm -f "$installer"
    return $rc
}

if ! command -v vocalinux &>/dev/null; then
    step "Installing Vocalinux" _install_vocalinux
else
    print_skip "Vocalinux already installed"
fi
