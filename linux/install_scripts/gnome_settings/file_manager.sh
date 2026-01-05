#!/bin/bash
# @name: File Manager
# @description: Nemo as default file manager, Nemo/Nautilus preferences, desktop icons
# @depends: gnome_packages.sh
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "File manager configuration"
skip_if_not_gnome "File manager configuration"

### Set Nemo as default file manager
step "Setting Nemo as default file manager" xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

### Nemo preferences
step_start "Configuring Nemo file manager"
run gsettings set org.nemo.preferences show-hidden-files true
run gsettings set org.nemo.preferences default-folder-viewer 'list-view'
run gsettings set org.nemo.preferences sort-directories-first true
step_end

### Desktop icon handling - transfer from Nautilus to Nemo
step_start "Configuring desktop icon handling"
run gsettings set org.gnome.desktop.background show-desktop-icons false
run gsettings set org.nemo.desktop show-desktop-icons true
step_end

### Nautilus preferences (only if installed)
if command -v nautilus &> /dev/null; then
    step_start "Configuring Nautilus file manager"
    run gsettings set org.gnome.nautilus.preferences show-hidden-files true
    run gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
    step_end
fi

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")

### Nemo autostart entry for desktop icons
setup_nemo_autostart() {
    mkdir -p ~/.config/autostart || return 1
    cp "$LINUX_DIR/dotfiles/nemo-desktop.desktop" ~/.config/autostart/
}
step "Creating Nemo desktop autostart entry" setup_nemo_autostart

### Prevent Nautilus from auto-launching and managing desktop
hide_nautilus_autostart() {
    mkdir -p ~/.config/autostart || return 1
    # Create minimal override file (idempotent - overwrites each time)
    printf '[Desktop Entry]\nHidden=true\n' > ~/.config/autostart/org.gnome.Nautilus.desktop
}
if [[ -f /etc/xdg/autostart/org.gnome.Nautilus.desktop ]]; then
    step "Hiding Nautilus autostart" hide_nautilus_autostart
fi
