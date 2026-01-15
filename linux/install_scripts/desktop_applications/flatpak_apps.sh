#!/bin/bash
# @name: Flatpak Apps
# @description: Obsidian, VS Code, Firefox, Inkscape, LibreOffice, Steam, Zotero, Tor Browser via Flatpak
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Flatpak applications"

# WSL has DBus/systemd issues with Flatpak; use Windows versions of these apps
if is_wsl; then
    print_skip "Flatpak applications (use Windows versions in WSL)"
    exit 0
fi

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
        # Verify installation succeeded before continuing
        if ! command -v flatpak &>/dev/null; then
            print_error "Flatpak installation failed"
            exit 1
        fi
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
install_flatpak_app "org.torproject.torbrowser-launcher" "Tor Browser"

### Update all Flatpak apps to latest versions
step "Updating Flatpak applications" flatpak update -y --user

### Set Firefox as default browser
if command -v xdg-settings &>/dev/null; then
    # Ensure Flatpak exports are in XDG_DATA_DIRS so xdg-settings can find the desktop file
    flatpak_exports="$HOME/.local/share/flatpak/exports/share"
    if [[ -d "$flatpak_exports" && ! "$XDG_DATA_DIRS" =~ "$flatpak_exports" ]]; then
        export XDG_DATA_DIRS="${flatpak_exports}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    fi
    
    step "Setting Firefox as default browser" xdg-settings set default-web-browser org.mozilla.firefox.desktop
fi
