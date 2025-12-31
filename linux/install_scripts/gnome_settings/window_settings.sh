#!/bin/bash
# @name: Window Settings
# @description: Mutter window management preferences
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Window settings"

step "Enabling center new windows" gsettings set org.gnome.mutter center-new-windows true
