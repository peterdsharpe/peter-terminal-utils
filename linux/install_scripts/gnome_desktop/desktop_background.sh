#!/bin/bash
# @name: Desktop Background
# @description: Set desktop wallpaper to Thank You image
# @headless: skip
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

### Convert to file:// URIs using Python for proper percent-encoding
### (handles spaces, #, %, and other special characters correctly)
percent_encode_path() {
    python3 -c "import sys; from urllib.parse import quote; print(quote(sys.argv[1], safe='/'))" "$1"
}
WALLPAPER_DAY_URI="file://$(percent_encode_path "$(realpath "$WALLPAPER_DAY")")"
WALLPAPER_NIGHT_URI="file://$(percent_encode_path "$(realpath "$WALLPAPER_NIGHT")")"

step "Setting desktop background" gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_DAY_URI"
step "Setting dark mode background" gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_NIGHT_URI"
