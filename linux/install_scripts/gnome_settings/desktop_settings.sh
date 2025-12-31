#!/bin/bash
# @name: Desktop Settings
# @description: Keyboard, touchpad, dark theme, Nemo file manager
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# Only run if not headless
if [[ "$HEADLESS" == "Y" ]]; then
    print_skip "GNOME desktop settings (headless mode)"
    exit 0
fi

# Individual settings - single commands
step "Disabling touchpad tap-and-drag" gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
step "Disabling GNOME animations" gsettings set org.gnome.desktop.interface enable-animations false

# Keyboard repeat (grouped - related settings)
step_start "Configuring faster keyboard repeat"
run gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25
run gsettings set org.gnome.desktop.peripherals.keyboard delay 300
step_end

step "Disabling hot corners" gsettings set org.gnome.desktop.interface enable-hot-corners false
step "Enabling locate pointer with Ctrl" gsettings set org.gnome.desktop.interface locate-pointer true
step "Enabling battery percentage display" gsettings set org.gnome.desktop.interface show-battery-percentage true
step "Enabling weekday in clock" gsettings set org.gnome.desktop.interface clock-show-weekday true
step "Enabling tap to click" gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
step "Enabling two-finger right click" gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
step "Enabling center new windows" gsettings set org.gnome.mutter center-new-windows true
step "Setting dark theme" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
step "Setting Nemo as default file manager" xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

# Nemo file manager settings (grouped)
step_start "Configuring Nemo file manager"
run gsettings set org.nemo.preferences show-hidden-files true
run gsettings set org.nemo.preferences default-folder-viewer 'list-view'
run gsettings set org.nemo.preferences sort-directories-first true
step_end

# Desktop icon handling - transfer from Nautilus to Nemo
step_start "Configuring desktop icon handling"
run gsettings set org.gnome.desktop.background show-desktop-icons false
run gsettings set org.nemo.desktop show-desktop-icons true
step_end

# Nautilus file manager settings (only if installed)
if command -v nautilus &> /dev/null; then
    step_start "Configuring Nautilus file manager"
    run gsettings set org.gnome.nautilus.preferences show-hidden-files true
    run gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
    step_end
fi

# Get the linux directory (for dotfiles path)
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Create nemo-desktop autostart entry
setup_nemo_autostart() {
    mkdir -p ~/.config/autostart || return 1
    cp "$LINUX_DIR/dotfiles/nemo-desktop.desktop" ~/.config/autostart/
}
step "Creating Nemo desktop autostart entry" setup_nemo_autostart

# Prevent Nautilus from auto-launching and managing desktop
hide_nautilus_autostart() {
    mkdir -p ~/.config/autostart || return 1
    # Create minimal override file (idempotent - overwrites each time)
    printf '[Desktop Entry]\nHidden=true\n' > ~/.config/autostart/org.gnome.Nautilus.desktop
}
if [[ -f /etc/xdg/autostart/org.gnome.Nautilus.desktop ]]; then
    step "Hiding Nautilus autostart" hide_nautilus_autostart
fi