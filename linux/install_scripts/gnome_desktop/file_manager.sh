#!/bin/bash
# @name: File Manager
# @description: Nemo as default file manager, Nemo/Nautilus preferences, desktop icons
# @depends: gnome_packages.sh
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "File manager configuration"
skip_if_not_gnome "File manager configuration"

### Helper to check if a gsettings schema exists
schema_exists() {
    gsettings list-schemas 2>/dev/null | grep -q "^$1$"
}

### Set Nemo as default file manager (only if Nemo is installed)
if command -v nemo &>/dev/null; then
    step "Setting Nemo as default file manager" xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
fi

### Nemo preferences (only if schema exists)
if schema_exists "org.nemo.preferences"; then
    step_start "Configuring Nemo file manager"
    run gsettings set org.nemo.preferences show-hidden-files true
    run gsettings set org.nemo.preferences default-folder-viewer 'list-view'
    run gsettings set org.nemo.preferences sort-directories-first true
    run gsettings set org.nemo.preferences show-advanced-permissions true
    run gsettings set org.nemo.preferences show-full-path-titles true
    run gsettings set org.nemo.preferences executable-text-activation 'launch'
    run gsettings set org.nemo.preferences ignore-view-metadata true
    step_end
else
    print_skip "Nemo preferences (Nemo not installed)"
fi

### Desktop icon handling - transfer from Nautilus to Nemo
if schema_exists "org.nemo.desktop"; then
    step_start "Configuring desktop icon handling"
    # This key may not exist on all GNOME versions
    if gsettings list-keys org.gnome.desktop.background 2>/dev/null | grep -q show-desktop-icons; then
        run gsettings set org.gnome.desktop.background show-desktop-icons false
    fi
    run gsettings set org.nemo.desktop show-desktop-icons true
    step_end
fi

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
