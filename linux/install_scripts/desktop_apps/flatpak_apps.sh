#!/bin/bash
# @name: Flatpak Apps
# @description: Obsidian, VS Code, Firefox, Inkscape, LibreOffice, Steam, Zotero via Flatpak
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Flatpak applications"

### Ensure flatpak is installed
install_flatpak() {
    case "$PKG_MANAGER" in
        apt) sudo apt-get install -yq flatpak ;;
        dnf) sudo dnf install -y flatpak ;;
        pacman) sudo pacman -S --noconfirm flatpak ;;
        zypper) sudo zypper install -y flatpak ;;
        *) echo "Cannot install flatpak: unsupported package manager" >&2; return 1 ;;
    esac
}

if ! command -v flatpak &>/dev/null; then
    if [[ "$HAS_SUDO" == true ]]; then
        step "Installing Flatpak" install_flatpak
    else
        print_skip "Flatpak (requires sudo to install)"
        exit 0
    fi
fi

### Add Flathub repository if not present
if ! flatpak remotes | grep -q flathub; then
    step "Adding Flathub repository" flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

### Install applications
# Using --user to avoid needing sudo for app installs (after flatpak itself is installed)
install_flatpak_app() {
    local app_id="$1"
    local app_name="$2"
    if flatpak list --app | grep -q "$app_id"; then
        print_skip "$app_name already installed"
    else
        step "Installing $app_name" flatpak install -y --user flathub "$app_id"
    fi
}

install_flatpak_app "md.obsidian.Obsidian" "Obsidian"
install_flatpak_app "org.zotero.Zotero" "Zotero"
install_flatpak_app "com.visualstudio.code" "VS Code"
install_flatpak_app "org.mozilla.firefox" "Firefox"
install_flatpak_app "org.inkscape.Inkscape" "Inkscape"
install_flatpak_app "org.libreoffice.LibreOffice" "LibreOffice"
install_flatpak_app "com.valvesoftware.Steam" "Steam"

### Set Firefox as default browser
if command -v xdg-settings &>/dev/null; then
    # Flatpak Firefox desktop file name
    step "Setting Firefox as default browser" xdg-settings set default-web-browser org.mozilla.firefox.desktop
fi
