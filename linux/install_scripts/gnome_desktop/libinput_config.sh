#!/bin/bash
# @name: Libinput Config
# @description: Custom scroll speed via LD_PRELOAD
# @depends: bootstrap.sh
# @requires: sudo
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Source: https://gitlab.com/warningnonpotablewater/libinput-config
#
# This uses LD_PRELOAD to intercept libinput calls and apply a scroll factor.
# Sandboxed apps (Flatpak/Snap) will show a harmless "cannot be preloaded" error
# because they can't access the host library path - see linux/docs/libinput-config.md

skip_if_headless "libinput-config"
skip_if_not_gnome "libinput-config"

# Requires sudo for system-wide installation
if [[ "${HAS_SUDO:-false}" == false ]]; then
    print_skip "libinput-config (requires sudo)"
    exit 0
fi

# Find libinput-config.so in known install locations (meson uses architecture-specific paths)
find_libinput_config_so() {
    local candidates=(
        "/usr/local/lib/$(gcc -dumpmachine 2>/dev/null)/libinput-config.so"
        "/usr/local/lib64/libinput-config.so"
        "/usr/local/lib/libinput-config.so"
    )
    for path in "${candidates[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

SCROLL_FACTOR="0.5"

# Check if already installed with correct config
LIBINPUT_CONFIG_SO=$(find_libinput_config_so)
if [[ -n "$LIBINPUT_CONFIG_SO" ]] && \
   grep -q "^scroll-factor=$SCROLL_FACTOR$" /etc/libinput.conf 2>/dev/null && \
   grep -q "$LIBINPUT_CONFIG_SO" /etc/ld.so.preload 2>/dev/null; then
    print_skip "libinput-config already configured"
    exit 0
fi

# Build dependencies + clone + build + install
step_start "Installing libinput-config"
case "$PKG_MANAGER" in
    apt) run sudo apt-get install -y meson ninja-build libinput-dev ;;
    dnf) run sudo dnf install -y meson ninja-build libinput-devel ;;
    pacman) run sudo pacman -S --noconfirm meson ninja libinput ;;
    *) print_error "Unsupported package manager for libinput-config dependencies"; exit 1 ;;
esac
tmpdir=$(mktemp -d)
run git clone --depth 1 https://gitlab.com/warningnonpotablewater/libinput-config.git "$tmpdir/libinput-config"
run meson setup "$tmpdir/libinput-config/build" "$tmpdir/libinput-config"
run ninja -C "$tmpdir/libinput-config/build"
run sudo ninja -C "$tmpdir/libinput-config/build" install
run rm -rf "$tmpdir"
step_end

# Configure scroll factor
step "Setting scroll-factor=$SCROLL_FACTOR" bash -c "echo 'scroll-factor=$SCROLL_FACTOR' | sudo tee /etc/libinput.conf"

# Find installed library (meson installs to architecture-specific paths)
LIBINPUT_CONFIG_SO=$(find_libinput_config_so)
if [[ -z "$LIBINPUT_CONFIG_SO" ]]; then
    print_error "Build failed: libinput-config.so not found in expected locations"
    exit 1
fi

# Ensure ld.so.preload entry exists (idempotent)
if ! grep -q "$LIBINPUT_CONFIG_SO" /etc/ld.so.preload 2>/dev/null; then
    step "Adding to /etc/ld.so.preload" bash -c "echo '$LIBINPUT_CONFIG_SO' | sudo tee -a /etc/ld.so.preload"
else
    print_skip "/etc/ld.so.preload already configured"
fi

print_info "Note: Sandboxed apps show a harmless preload error - see linux/docs/libinput-config.md"
