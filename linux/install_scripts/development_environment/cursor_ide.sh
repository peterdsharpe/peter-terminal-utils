#!/bin/bash
# @name: Cursor IDE
# @description: Full Cursor IDE with PeterProfile configuration
# @depends: bootstrap.sh
# @headless: skip
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Cursor IDE"

# WSL uses Cursor installed on Windows host - don't install Linux version
if is_wsl; then
    print_skip "Cursor IDE (use Windows installation in WSL)"
    exit 0
fi

LINUX_DIR=$(get_linux_dir "${BASH_SOURCE[0]}")
CURSOR_CONFIG_SRC="$LINUX_DIR/dotfiles/cursor-config"
CURSOR_CONFIG_DEST="$HOME/.config/Cursor/User"

###############################################################################
### Download and Install Cursor IDE
###############################################################################

# Cache for API response (avoid duplicate network calls)
_CURSOR_API_CACHE=""

# Fetch latest version info from Cursor API (cached)
get_cursor_info() {
    if [[ -n "$_CURSOR_API_CACHE" ]]; then
        echo "$_CURSOR_API_CACHE"
        return 0
    fi
    
    local platform="linux-x64"
    [[ "$ARCH" == "arm64" ]] && platform="linux-arm64"
    
    _CURSOR_API_CACHE=$(curl -sL "https://cursor.com/api/download?platform=${platform}&releaseTrack=stable" 2>/dev/null)
    echo "$_CURSOR_API_CACHE"
}

# Get latest version from API
get_latest_version() {
    local info
    info=$(get_cursor_info) || return 1
    echo "$info" | jq -r '.version // empty'
}

# Get installed version (works for both deb and AppImage)
get_installed_version() {
    # Best source: cursor --version returns clean semver (e.g., "2.2.44")
    if command -v cursor &>/dev/null; then
        local cli_version
        cli_version=$(cursor --version 2>/dev/null | head -1)
        if [[ -n "$cli_version" && "$cli_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            echo "$cli_version"
            return 0
        fi
    fi
    
    # Fallback: AppImage version file
    local appimage_version_file="$HOME/.local/share/cursor/.version"
    if [[ -f "$appimage_version_file" ]]; then
        cat "$appimage_version_file"
        return 0
    fi
    
    return 1
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

# Smart install: use deb on apt-based distros with sudo, AppImage otherwise
install_cursor_smart() {
    if [[ "$PKG_MANAGER" == "apt" ]] && [[ "${HAS_SUDO:-false}" == true ]]; then
        install_cursor_deb
    else
        install_cursor_appimage
    fi
}

# Check versions and install/update if needed
check_and_install_cursor() {
    local installed_version latest_version
    installed_version=$(get_installed_version)
    latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        echo "Failed to fetch latest Cursor version from API" >&2
        return 1
    fi
    
    if [[ -z "$installed_version" ]]; then
        step "Installing Cursor IDE ($latest_version)" install_cursor_smart
    elif [[ "$installed_version" == "$latest_version" ]]; then
        print_skip "Cursor IDE already at latest version ($installed_version)"
    else
        step "Updating Cursor IDE ($installed_version -> $latest_version)" install_cursor_smart
    fi
}

check_and_install_cursor

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

# Profile name to configure (must match what's created in Cursor)
PROFILE_NAME="PeterProfile"
STORAGE_JSON="$CURSOR_CONFIG_DEST/globalStorage/storage.json"

# Find profile ID from Cursor's storage.json
# Returns empty string if profile doesn't exist
get_profile_id() {
    local profile_name="$1"
    if [[ ! -f "$STORAGE_JSON" ]]; then
        return 0
    fi
    jq -r --arg name "$profile_name" \
        '.userDataProfiles[]? | select(.name == $name) | .location // empty' \
        "$STORAGE_JSON" 2>/dev/null
}

# Check if profile settings are correctly symlinked
cursor_config_correct() {
    local profile_id
    profile_id=$(get_profile_id "$PROFILE_NAME")
    
    if [[ -z "$profile_id" ]]; then
        # Profile doesn't exist yet - can't be correct
        return 1
    fi
    
    local profile_dir="$CURSOR_CONFIG_DEST/profiles/$profile_id"
    local src_dir="$CURSOR_CONFIG_SRC/$PROFILE_NAME"
    
    # Check that settings files are correctly symlinked
    for file in settings.json keybindings.json; do
        local dest="$profile_dir/$file"
        local src="$src_dir/$file"
        
        # Skip files that don't exist in source (consistent with setup_cursor_config)
        if [[ ! -f "$src" ]]; then
            continue
        fi
        
        # Source exists, so dest must be a symlink pointing to it
        if [[ ! -L "$dest" ]]; then
            return 1
        fi
        
        local current_target expected_target
        current_target=$(readlink -f "$dest")
        expected_target=$(readlink -f "$src")
        
        if [[ "$current_target" != "$expected_target" ]]; then
            return 1
        fi
    done
    
    return 0
}

setup_cursor_config() {
    local src_dir="$CURSOR_CONFIG_SRC/$PROFILE_NAME"
    
    # Check if source config exists
    if [[ ! -d "$src_dir" ]]; then
        echo "Warning: Profile config not found at $src_dir" >&2
        return 1
    fi
    
    # Handle migration from old approach: if $CURSOR_CONFIG_DEST is itself a
    # symlink (e.g., pointing to dotfiles/cursor-config), we need to replace it
    # with a real directory.
    if [[ -L "$CURSOR_CONFIG_DEST" ]]; then
        echo "Migrating from old config symlink approach..."
        local old_target
        old_target=$(readlink -f "$CURSOR_CONFIG_DEST")
        rm "$CURSOR_CONFIG_DEST"
        mkdir -p "$CURSOR_CONFIG_DEST"
        
        # Copy over non-profile files from old location
        for item in globalStorage workspaceStorage History extensions.json; do
            if [[ -e "$old_target/$item" ]]; then
                cp -a "$old_target/$item" "$CURSOR_CONFIG_DEST/" 2>/dev/null || true
            fi
        done
    fi
    
    # Ensure Cursor User config directory exists
    mkdir -p "$CURSOR_CONFIG_DEST"
    
    # Handle migration from old profiles/ symlink approach
    # Old setup: ~/.config/Cursor/User/profiles → dotfiles/cursor-config/profiles
    # New setup: individual file symlinks inside the profile directory
    local profiles_dir="$CURSOR_CONFIG_DEST/profiles"
    if [[ -L "$profiles_dir" ]]; then
        echo "Migrating from old profiles symlink approach..."
        local old_profiles_target
        old_profiles_target=$(readlink -f "$profiles_dir" 2>/dev/null)
        
        # Remove the symlink so we can create a real directory
        rm "$profiles_dir"
        mkdir -p "$profiles_dir"
        
        # If the old target had content, copy it over (preserves profile directories)
        if [[ -d "$old_profiles_target" ]]; then
            # Copy profile directories (the hashed ones like 4404ae3a/)
            for profile_subdir in "$old_profiles_target"/*/; do
                if [[ -d "$profile_subdir" ]]; then
                    local subdir_name
                    subdir_name=$(basename "$profile_subdir")
                    cp -a "$profile_subdir" "$profiles_dir/$subdir_name" 2>/dev/null || true
                fi
            done
        fi
    fi
    
    # Find the profile ID for PeterProfile
    local profile_id
    profile_id=$(get_profile_id "$PROFILE_NAME")
    
    if [[ -z "$profile_id" ]]; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════════╗"
        echo "║  PeterProfile not found in Cursor                                ║"
        echo "╠══════════════════════════════════════════════════════════════════╣"
        if [[ ! -f "$STORAGE_JSON" ]]; then
        echo "║  Cursor hasn't been opened yet. Please:                          ║"
        echo "║                                                                  ║"
        echo "║  1. Open Cursor IDE for the first time                           ║"
        echo "║  2. Complete any initial setup prompts                           ║"
        echo "║  3. Go to: gear icon (bottom-left) → Profiles → Create Profile   ║"
        else
        echo "║  Please create the profile manually:                             ║"
        echo "║                                                                  ║"
        echo "║  1. Open Cursor IDE                                              ║"
        echo "║  2. Click the gear icon (bottom-left) → Profiles                 ║"
        echo "║  3. Click 'Create Profile'                                       ║"
        fi
        echo "║  4. Name it exactly: PeterProfile                                ║"
        echo "║  5. Re-run this install script                                   ║"
        echo "╚══════════════════════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi
    
    local profile_dir="$CURSOR_CONFIG_DEST/profiles/$profile_id"
    
    # Ensure profile directory exists
    mkdir -p "$profile_dir"
    
    # Symlink settings files from dotfiles into the profile directory
    for file in settings.json keybindings.json; do
        local src="$src_dir/$file"
        local dest="$profile_dir/$file"
        
        if [[ ! -f "$src" ]]; then
            continue
        fi
        
        # Backup existing file if it's not a symlink
        if [[ -f "$dest" ]] && [[ ! -L "$dest" ]]; then
            local backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$dest" "$backup"
            echo "Backed up existing $file to $backup"
        fi
        
        # Remove existing symlink if pointing to wrong location
        if [[ -L "$dest" ]]; then
            local current_target expected_target
            current_target=$(readlink -f "$dest")
            expected_target=$(readlink -f "$src")
            if [[ "$current_target" != "$expected_target" ]]; then
                rm "$dest"
            fi
        fi
        
        # Create symlink if needed
        if [[ ! -L "$dest" ]]; then
            ln -sf "$src" "$dest" || return 1
            echo "Linked $file → $src"
        fi
    done
    
    # Note: These stay local (machine-specific):
    # - globalStorage/ - SQLite databases, machine state
    # - workspaceStorage/ - workspace caches
    # - History/ - local file edit history
    # - extensions.json - absolute paths to extensions
}

if cursor_config_correct; then
    print_skip "Cursor PeterProfile already configured"
else
    if ! step "Configuring Cursor PeterProfile" setup_cursor_config; then
        # Profile setup failed - don't print success at the end
        exit 1
    fi
fi

###############################################################################
### Extension Management
###############################################################################

# Extensions are managed per-machine (NOT synced via dotfiles).
# 
# Why? extensions.json contains:
#   - Absolute file paths (/home/peter/.cursor/extensions/...)
#   - Platform-specific binaries (-linux-x64, -darwin-arm64, etc.)
#   - Machine-specific metadata
#
# Instead, we maintain extensions.txt with extension IDs.
# Install extensions after first Cursor launch with:
#   while read ext; do cursor --install-extension "$ext"; done < extensions.txt
#
# This approach ensures:
#   ✓ Extensions work correctly on each platform
#   ✓ No git noise from extension updates
#   ✓ Fresh installs get the right platform-specific versions

if [[ -f "$CURSOR_CONFIG_SRC/extensions.txt" ]]; then
    print_info "Extensions list available at: $CURSOR_CONFIG_SRC/extensions.txt"
    print_info "Install after first Cursor launch with:"
    print_info "  while read ext; do cursor --install-extension \"\$ext\"; done < $CURSOR_CONFIG_SRC/extensions.txt"
fi

print_success "Cursor IDE setup complete"
