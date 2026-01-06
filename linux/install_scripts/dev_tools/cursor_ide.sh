#!/bin/bash
# @name: Cursor IDE
# @description: Full Cursor IDE with PeterProfile configuration
# @depends: core_packages.sh
# @headless: skip
# @parallel: false
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Cursor IDE"

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")
CURSOR_CONFIG_SRC="$LINUX_DIR/dotfiles/cursor-config"
CURSOR_CONFIG_DEST="$HOME/.config/Cursor/User"

###############################################################################
### Download and Install Cursor IDE
###############################################################################

# Fetch latest version info from Cursor API
get_cursor_info() {
    local platform="linux-x64"
    [[ "$ARCH" == "arm64" ]] && platform="linux-arm64"
    
    curl -sL "https://cursor.com/api/download?platform=${platform}&releaseTrack=stable" 2>/dev/null
}

# Install via AppImage (cross-distro, user-level)
install_cursor_appimage() {
    local info download_url version
    info=$(get_cursor_info) || return 1
    download_url=$(echo "$info" | jq -r '.downloadUrl') || return 1
    version=$(echo "$info" | jq -r '.version') || return 1
    
    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        echo "Failed to get download URL from Cursor API" >&2
        return 1
    fi
    
    local install_dir="$HOME/.local/share/cursor"
    local appimage_path="$install_dir/cursor.AppImage"
    
    mkdir -p "$install_dir" || return 1
    
    echo "Downloading Cursor $version..."
    curl -L "$download_url" -o "$appimage_path" || return 1
    chmod +x "$appimage_path" || return 1
    
    # Create symlink in ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    # Create a wrapper script that handles the AppImage
    cat > "$HOME/.local/bin/cursor" << 'WRAPPER'
#!/bin/bash
# Cursor IDE launcher (installed by peter-terminal-utils)
exec "$HOME/.local/share/cursor/cursor.AppImage" "$@"
WRAPPER
    chmod +x "$HOME/.local/bin/cursor"
    
    echo "$version" > "$install_dir/.version"
}

# Install via deb package (apt-based distros, system-wide)
install_cursor_deb() {
    local info deb_url version
    info=$(get_cursor_info) || return 1
    deb_url=$(echo "$info" | jq -r '.debUrl') || return 1
    version=$(echo "$info" | jq -r '.version') || return 1
    
    if [[ -z "$deb_url" || "$deb_url" == "null" ]]; then
        echo "Failed to get deb URL from Cursor API" >&2
        return 1
    fi
    
    local tmp_deb
    tmp_deb=$(mktemp --suffix=.deb) || return 1
    
    echo "Downloading Cursor $version..."
    curl -L "$deb_url" -o "$tmp_deb" || { rm -f "$tmp_deb"; return 1; }
    
    sudo dpkg -i "$tmp_deb" || sudo apt-get install -f -y
    local result=$?
    rm -f "$tmp_deb"
    return $result
}

# Check if Cursor IDE is already installed
cursor_installed() {
    # Check for deb-installed cursor
    if command -v cursor &>/dev/null; then
        local cursor_path
        cursor_path=$(command -v cursor)
        # If it's not our wrapper script, it's probably deb-installed
        if [[ "$cursor_path" != "$HOME/.local/bin/cursor" ]]; then
            return 0
        fi
        # Check if our AppImage exists
        if [[ -f "$HOME/.local/share/cursor/cursor.AppImage" ]]; then
            return 0
        fi
    fi
    # Check for AppImage directly
    [[ -f "$HOME/.local/share/cursor/cursor.AppImage" ]]
}

# Smart install: use deb on apt-based distros with sudo, AppImage otherwise
install_cursor_smart() {
    if [[ "$PKG_MANAGER" == "apt" ]] && [[ "${HAS_SUDO:-false}" == true ]]; then
        install_cursor_deb
    else
        install_cursor_appimage
    fi
}

# Install Cursor IDE if not present
if ! cursor_installed; then
    step "Installing Cursor IDE" install_cursor_smart
else
    print_skip "Cursor IDE already installed"
fi

###############################################################################
### Create Desktop Entry (for AppImage installs)
###############################################################################

DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"

desktop_entry_exists() {
    [[ -f "$DESKTOP_FILE" ]] && grep -q "cursor.AppImage" "$DESKTOP_FILE" 2>/dev/null
}

create_desktop_entry() {
    local desktop_dir="$HOME/.local/share/applications"
    local icon_dir="$HOME/.local/share/icons"
    
    # Only create if using AppImage (deb creates its own)
    if [[ ! -f "$HOME/.local/share/cursor/cursor.AppImage" ]]; then
        return 0
    fi
    
    mkdir -p "$desktop_dir" "$icon_dir"
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-powered code editor
Exec=$HOME/.local/share/cursor/cursor.AppImage --no-sandbox %F
Icon=cursor
Type=Application
Categories=Development;IDE;TextEditor;
MimeType=text/plain;inode/directory;
StartupNotify=true
StartupWMClass=Cursor
EOF
    
    # Update desktop database
    update-desktop-database "$desktop_dir" 2>/dev/null || true
}

if [[ -f "$HOME/.local/share/cursor/cursor.AppImage" ]]; then
    if desktop_entry_exists; then
        print_skip "Desktop entry already exists"
    else
        step "Creating desktop entry" create_desktop_entry
    fi
fi

###############################################################################
### Configure Cursor with PeterProfile settings
###############################################################################

# Check if config is already correctly symlinked
cursor_config_correct() {
    # Check if destination is a symlink pointing to our source
    if [[ -L "$CURSOR_CONFIG_DEST" ]]; then
        local current_target
        current_target=$(readlink -f "$CURSOR_CONFIG_DEST")
        local expected_target
        expected_target=$(readlink -f "$CURSOR_CONFIG_SRC")
        [[ "$current_target" == "$expected_target" ]]
    else
        return 1
    fi
}

setup_cursor_config() {
    # Check if source config exists
    if [[ ! -d "$CURSOR_CONFIG_SRC" ]]; then
        echo "Warning: Cursor config source not found at $CURSOR_CONFIG_SRC" >&2
        return 1
    fi
    
    # Backup existing config if it exists and is not a symlink
    if [[ -d "$CURSOR_CONFIG_DEST" ]] && [[ ! -L "$CURSOR_CONFIG_DEST" ]]; then
        local backup_dir
        backup_dir="$CURSOR_CONFIG_DEST.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$CURSOR_CONFIG_DEST" "$backup_dir" || return 1
        echo "Backed up existing config to $backup_dir"
    fi
    
    # Remove existing symlink if present (and not already correct)
    [[ -L "$CURSOR_CONFIG_DEST" ]] && rm "$CURSOR_CONFIG_DEST"
    
    # Create parent directory
    mkdir -p "$(dirname "$CURSOR_CONFIG_DEST")"
    
    # Create symlink
    ln -sf "$CURSOR_CONFIG_SRC" "$CURSOR_CONFIG_DEST"
}

if cursor_config_correct; then
    print_skip "Cursor config already symlinked"
else
    step "Configuring Cursor with PeterProfile" setup_cursor_config
fi

###############################################################################
### Install Extensions (optional, on first run)
###############################################################################

# Extensions are listed in cursor-config/extensions.txt
# They can be installed after Cursor first launch with:
#   while read ext; do cursor --install-extension "$ext"; done < extensions.txt
# 
# We don't do this automatically because:
# 1. Cursor needs to run at least once to initialize
# 2. Extension installation can be slow and may require network
# 3. Some extensions may not be available in Cursor's marketplace

if [[ -f "$CURSOR_CONFIG_SRC/extensions.txt" ]]; then
    print_info "Extensions list available at: $CURSOR_CONFIG_SRC/extensions.txt"
    print_info "Install after first Cursor launch with:"
    print_info "  while read ext; do cursor --install-extension \"\$ext\"; done < $CURSOR_CONFIG_SRC/extensions.txt"
fi

print_success "Cursor IDE setup complete"
