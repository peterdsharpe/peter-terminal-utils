#!/bin/bash
# @name: Favorite Apps
# @description: Pin apps to dash/panel in preferred order
# @depends: flatpak_apps, cursor, signal
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Favorite apps configuration"
skip_if_not_gnome "Favorite apps configuration"

###############################################################################
### Define Pinned Apps (in order)
###############################################################################
#
# These are .desktop file names (basename only). The script will:
#   1. Check if each .desktop file exists in standard locations
#   2. Only include apps that are actually installed
#   3. Set them in the exact order specified
#
# Common locations checked:
#   - /usr/share/applications/
#   - /var/lib/flatpak/exports/share/applications/
#   - /var/lib/snapd/desktop/applications/
#   - ~/.local/share/applications/
#   - ~/.local/share/flatpak/exports/share/applications/

FAVORITE_APPS=(
    # File manager
    "nemo.desktop"
    # Terminal
    "org.gnome.Ptyxis.desktop"
    # Browser
    "org.mozilla.firefox.desktop"
    # Code editor
    "cursor.desktop"
    # Reference manager
    "org.zotero.Zotero.desktop"
    # Communication
    "signal-desktop_signal-desktop.desktop"
)

###############################################################################
### Helper Functions
###############################################################################

# Check if a .desktop file exists in any standard location
desktop_file_exists() {
    local desktop_name="$1"
    local search_paths=(
        "/usr/share/applications"
        "/var/lib/flatpak/exports/share/applications"
        "/var/lib/snapd/desktop/applications"
        "$HOME/.local/share/applications"
        "$HOME/.local/share/flatpak/exports/share/applications"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path/$desktop_name" ]]; then
            return 0
        fi
    done
    return 1
}

###############################################################################
### Build and Apply Favorites List
###############################################################################

configure_favorite_apps() {
    local available_apps=()
    local skipped_apps=()
    
    # Filter to only installed apps
    for app in "${FAVORITE_APPS[@]}"; do
        if desktop_file_exists "$app"; then
            available_apps+=("$app")
        else
            skipped_apps+=("$app")
        fi
    done
    
    # Log skipped apps
    if [[ ${#skipped_apps[@]} -gt 0 ]]; then
        print_info "Skipping apps not installed: ${skipped_apps[*]}"
    fi
    
    if [[ ${#available_apps[@]} -eq 0 ]]; then
        print_warning "No favorite apps found - keeping current favorites"
        return 0
    fi
    
    # Build GSettings array format: ['app1.desktop', 'app2.desktop', ...]
    local favorites_str
    favorites_str=$(printf "'%s', " "${available_apps[@]}")
    favorites_str="[${favorites_str%, }]"  # Remove trailing comma and wrap in []
    
    print_info "Setting ${#available_apps[@]} pinned apps"
    gsettings set org.gnome.shell favorite-apps "$favorites_str"
}

step "Configuring pinned apps in dash" configure_favorite_apps
