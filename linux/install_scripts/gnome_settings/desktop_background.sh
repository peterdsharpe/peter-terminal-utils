#!/bin/bash
# @name: Desktop Background
# @description: Set desktop wallpaper to Thank You image
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Desktop background"
skip_if_not_gnome "Desktop background"

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")
WALLPAPER_DAY="$LINUX_DIR/../assets/Thank You.png"
WALLPAPER_NIGHT="$LINUX_DIR/../assets/Thank You Night.png"

if [ ! -f "$WALLPAPER_DAY" ]; then
    print_error "Day wallpaper not found: $WALLPAPER_DAY"
    exit 1
fi

if [ ! -f "$WALLPAPER_NIGHT" ]; then
    print_error "Night wallpaper not found: $WALLPAPER_NIGHT"
    exit 1
fi

### Convert to file:// URIs (spaces must be percent-encoded)
WALLPAPER_DAY_URI="file://$(realpath "$WALLPAPER_DAY" | sed 's/ /%20/g')"
WALLPAPER_NIGHT_URI="file://$(realpath "$WALLPAPER_NIGHT" | sed 's/ /%20/g')"

step "Setting desktop background" gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_DAY_URI"
step "Setting dark mode background" gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_NIGHT_URI"
