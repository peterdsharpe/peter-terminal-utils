#!/bin/bash
# @name: Libinput Config
# @description: Custom scroll speed via LD_PRELOAD
# @requires: sudo
# @headless: skip
# @parallel: false
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
# Source: https://gitlab.com/warningnonpotablewater/libinput-config
#
# This uses LD_PRELOAD to intercept libinput calls and apply a scroll factor.
# Sandboxed apps (Flatpak/Snap) will show a harmless "cannot be preloaded" error
# because they can't access the host's /usr/local/lib64 - see linux/docs/libinput-config.md

# Skip in headless mode (no pointing devices to configure)
if [[ "$HEADLESS" == "Y" ]]; then
    print_skip "libinput-config (headless mode)"
    exit 0
fi

# Requires sudo for system-wide installation
if [[ "${HAS_SUDO:-false}" == false ]]; then
    print_skip "libinput-config (requires sudo)"
    exit 0
fi

SCROLL_FACTOR="0.5"
LIBINPUT_CONFIG_SO="/usr/local/lib64/libinput-config.so"

# Check if already installed with correct config
if [[ -f "$LIBINPUT_CONFIG_SO" ]] && \
   grep -q "^scroll-factor=$SCROLL_FACTOR$" /etc/libinput.conf 2>/dev/null && \
   grep -q "$LIBINPUT_CONFIG_SO" /etc/ld.so.preload 2>/dev/null; then
    print_skip "libinput-config already configured"
    exit 0
fi

# Build dependencies + clone + build + install
step_start "Installing libinput-config"
run sudo apt-get install -y meson ninja-build libinput-dev
tmpdir=$(mktemp -d)
run git clone --depth 1 https://gitlab.com/warningnonpotablewater/libinput-config.git "$tmpdir/libinput-config"
run meson setup "$tmpdir/libinput-config/build" "$tmpdir/libinput-config"
run ninja -C "$tmpdir/libinput-config/build"
run sudo ninja -C "$tmpdir/libinput-config/build" install
run rm -rf "$tmpdir"
step_end

# Configure scroll factor
step "Setting scroll-factor=$SCROLL_FACTOR" bash -c "echo 'scroll-factor=$SCROLL_FACTOR' | sudo tee /etc/libinput.conf"

# Verify installation succeeded before modifying ld.so.preload
if [[ ! -f "$LIBINPUT_CONFIG_SO" ]]; then
    print_error "Build failed: $LIBINPUT_CONFIG_SO not found"
    exit 1
fi

# Ensure ld.so.preload entry exists (idempotent)
if ! grep -q "$LIBINPUT_CONFIG_SO" /etc/ld.so.preload 2>/dev/null; then
    step "Adding to /etc/ld.so.preload" bash -c "echo '$LIBINPUT_CONFIG_SO' | sudo tee -a /etc/ld.so.preload"
else
    print_skip "/etc/ld.so.preload already configured"
fi

print_info "Note: Sandboxed apps show a harmless preload error - see linux/docs/libinput-config.md"
