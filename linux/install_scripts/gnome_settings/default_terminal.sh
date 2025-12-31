#!/bin/bash
# @name: Default Terminal
# @description: Set Ptyxis as default terminal system-wide
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Default terminal configuration"

PTYXIS_EXEC='flatpak run app.devsuite.Ptyxis --new-window'
PTYXIS_DESKTOP='app.devsuite.Ptyxis.desktop'

### Cinnamon default terminal (used by Nemo "Open in Terminal")
step "Setting Ptyxis as default terminal for Nemo" gsettings set org.cinnamon.desktop.default-applications.terminal exec "$PTYXIS_EXEC"

### GNOME default terminal (used by Ctrl+Alt+T and GNOME-native apps)
step "Setting Ptyxis as default terminal for GNOME" gsettings set org.gnome.desktop.default-applications.terminal exec "$PTYXIS_EXEC"

### XDG terminals list (modern freedesktop.org standard)
setup_xdg_terminals() {
    mkdir -p ~/.config || return 1
    echo "$PTYXIS_DESKTOP" > ~/.config/xdg-terminals.list
}
step "Setting Ptyxis in xdg-terminals.list" setup_xdg_terminals
