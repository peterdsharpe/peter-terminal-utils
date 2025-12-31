#!/bin/bash
# @name: Input Settings
# @description: Touchpad and keyboard repeat configuration
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Input settings"

### Touchpad settings
step "Disabling touchpad tap-and-drag" gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
step "Enabling tap to click" gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
step "Enabling two-finger right click" gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'

### Keyboard repeat settings
step_start "Configuring faster keyboard repeat"
run gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
run gsettings set org.gnome.desktop.peripherals.keyboard delay 300
step_end
