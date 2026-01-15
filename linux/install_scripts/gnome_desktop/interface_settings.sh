#!/bin/bash
# @name: Interface Settings
# @description: Theme, animations, clock, fonts, and display preferences
# @depends: firacode.sh
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Interface settings"
skip_if_not_gnome "Interface settings"

### Appearance
step "Setting dark theme" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
step "Disabling GNOME animations" gsettings set org.gnome.desktop.interface enable-animations false

### Font rendering (GNOME Tweaks equivalent settings)
step "Setting monospace font to FiraCode Nerd Font" gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font Mono 11'
step "Setting font hinting to full" gsettings set org.gnome.desktop.interface font-hinting 'full'
step "Setting font antialiasing to subpixel (LCD)" gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'

### Accessibility / usability
step "Disabling hot corners" gsettings set org.gnome.desktop.interface enable-hot-corners false
step "Enabling locate pointer with Ctrl" gsettings set org.gnome.desktop.interface locate-pointer true

### Top bar display
step "Enabling battery percentage display" gsettings set org.gnome.desktop.interface show-battery-percentage true
step "Enabling weekday in clock" gsettings set org.gnome.desktop.interface clock-show-weekday true
