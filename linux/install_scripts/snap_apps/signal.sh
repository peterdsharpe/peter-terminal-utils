#!/bin/bash
# @name: Signal Desktop
# @description: Encrypted messaging app via official apt repository
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_signal() {
    # Official Signal apt repository - https://signal.org/download/linux/
    curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null || return 1
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee /etc/apt/sources.list.d/signal-xenial.list > /dev/null || return 1
    sudo apt-get update -qq || return 1
    sudo apt-get install -yq signal-desktop
}

ensure_command "Signal Desktop" signal-desktop install_signal sudo

