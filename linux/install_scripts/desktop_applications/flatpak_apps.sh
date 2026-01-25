#!/bin/bash
# @name: Flatpak Apps
# @description: Productivity, creative, and media apps via Flatpak
# @depends: bootstrap.sh
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Flatpak applications"

### Ensure flatpak is installed
install_flatpak() {
    pkg_install flatpak
}

FLATPAK_FRESHLY_INSTALLED=false
if ! command -v flatpak &>/dev/null; then
    if [[ "$HAS_SUDO" == true ]]; then
        step "Installing Flatpak" install_flatpak
        # Verify installation succeeded before continuing
        if ! command -v flatpak &>/dev/null; then
            print_error "Flatpak installation failed - check package manager output above"
            exit 1
        fi
        FLATPAK_FRESHLY_INSTALLED=true
    else
        print_skip "Flatpak (requires sudo to install)"
        exit 0
    fi
fi

### Add Flathub repository if not present (user-level to match --user installs)
if ! flatpak remotes --user | grep -q flathub; then
    step "Adding Flathub repository" flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

### Install applications
# Using --user to avoid needing sudo for app installs (after flatpak itself is installed)
install_flatpak_app() {
    local app_id="$1"
    local app_name="$2"
    # flatpak info succeeds if app is installed (user OR system)
    if flatpak info "$app_id" &>/dev/null; then
        print_skip "$app_name already installed"
    else
        step "Installing $app_name" flatpak install -y --user flathub "$app_id"
    fi
}

install_flatpak_app "io.github.flattool.Warehouse" "Warehouse"  # Flatpak management GUI
install_flatpak_app "md.obsidian.Obsidian" "Obsidian"
install_flatpak_app "org.zotero.Zotero" "Zotero"
install_flatpak_app "com.visualstudio.code" "VS Code"
install_flatpak_app "org.mozilla.firefox" "Firefox"
install_flatpak_app "org.inkscape.Inkscape" "Inkscape"
install_flatpak_app "org.libreoffice.LibreOffice" "LibreOffice"
install_flatpak_app "com.valvesoftware.Steam" "Steam"
install_flatpak_app "org.torproject.torbrowser-launcher" "Tor Browser"
install_flatpak_app "org.gimp.GIMP" "GIMP"
install_flatpak_app "org.blender.Blender" "Blender"
install_flatpak_app "com.transmissionbt.Transmission" "Transmission"
install_flatpak_app "com.prusa3d.PrusaSlicer" "PrusaSlicer"

### Update all Flatpak apps to latest versions
step "Updating Flatpak applications" flatpak update -y --user

### Cleanup: remove unused runtimes and clear cache
step "Removing unused runtimes" flatpak uninstall -y --user --unused
if [[ -d "$HOME/.cache/flatpak" ]]; then
    step "Clearing Flatpak cache" rm -rf "$HOME/.cache/flatpak"
fi

### Set Firefox as default browser
if command -v xdg-settings &>/dev/null; then
    # Ensure Flatpak exports are in XDG_DATA_DIRS so xdg-settings can find the desktop file
    flatpak_exports="$HOME/.local/share/flatpak/exports/share"
    if [[ -d "$flatpak_exports" && ! "$XDG_DATA_DIRS" =~ "$flatpak_exports" ]]; then
        export XDG_DATA_DIRS="${flatpak_exports}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    fi
    
    step "Setting Firefox as default browser" xdg-settings set default-web-browser org.mozilla.firefox.desktop
fi

### Warn about session restart if Flatpak was freshly installed
if [[ "$FLATPAK_FRESHLY_INSTALLED" == true ]]; then
    print_warning "Flatpak was installed during this session. Log out and back in for apps to appear in the application menu."
fi
