#!/bin/bash
# @name: Default Terminal
# @description: Set Ptyxis as default terminal for Nemo right-click menu
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Default terminal configuration"

# Set Ptyxis as the default terminal for Nemo's "Open in Terminal" action
# Uses cinnamon's terminal preference which Nemo respects
step "Setting Ptyxis as default terminal for Nemo" gsettings set org.cinnamon.desktop.default-applications.terminal exec 'flatpak run app.devsuite.Ptyxis --new-window'
