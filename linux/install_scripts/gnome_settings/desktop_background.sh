#!/bin/bash
# @name: Desktop Background
# @description: Set desktop wallpaper to Thank You image
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Desktop background"

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")
WALLPAPER="$LINUX_DIR/../assets/Thank You (3840x2160).png"

if [ ! -f "$WALLPAPER" ]; then
    print_error "Wallpaper not found: $WALLPAPER"
    exit 1
fi

### Convert to file:// URI (spaces must be percent-encoded)
WALLPAPER_URI="file://$(realpath "$WALLPAPER" | sed 's/ /%20/g')"

step "Setting desktop background" gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
step "Setting dark mode background" gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
