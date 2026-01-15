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

# Check if config is already correctly symlinked
cursor_config_correct() {
    # Check if profiles directory is correctly symlinked
    local profile_dest="$CURSOR_CONFIG_DEST/profiles"
    local profile_src="$CURSOR_CONFIG_SRC/profiles"
    
    if [[ ! -L "$profile_dest" ]]; then
        return 1
    fi
    
    local current_target
    current_target=$(readlink -f "$profile_dest")
    local expected_target
    expected_target=$(readlink -f "$profile_src")
    
    [[ "$current_target" == "$expected_target" ]]
}

setup_cursor_config() {
    # Check if source config exists
    if [[ ! -d "$CURSOR_CONFIG_SRC" ]]; then
        echo "Warning: Cursor config source not found at $CURSOR_CONFIG_SRC" >&2
        return 1
    fi
    
    # Handle migration from old approach: if $CURSOR_CONFIG_DEST is itself a
    # symlink (e.g., pointing to dotfiles/cursor-config), we need to replace it
    # with a real directory. Otherwise, creating symlinks inside it would write
    # into the dotfiles directory and create circular references.
    if [[ -L "$CURSOR_CONFIG_DEST" ]]; then
        echo "Migrating from old config symlink approach..."
        local old_target
        old_target=$(readlink -f "$CURSOR_CONFIG_DEST")
        rm "$CURSOR_CONFIG_DEST"
        mkdir -p "$CURSOR_CONFIG_DEST"
        
        # Copy over non-profile files from old location (globalStorage, etc.)
        # These are machine-specific and shouldn't be symlinked
        for item in globalStorage workspaceStorage History extensions.json; do
            if [[ -e "$old_target/$item" ]]; then
                cp -a "$old_target/$item" "$CURSOR_CONFIG_DEST/" 2>/dev/null || true
            fi
        done
    fi
    
    # Ensure Cursor User config directory exists
    mkdir -p "$CURSOR_CONFIG_DEST"
    
    # Copy global settings files (optional, if they exist at root level)
    # These are less common but we'll handle them if present
    for item in settings.json keybindings.json; do
        local src="$CURSOR_CONFIG_SRC/$item"
        local dest="$CURSOR_CONFIG_DEST/$item"
        
        if [[ -f "$src" ]]; then
            # Only copy if destination doesn't exist or is older
            if [[ ! -f "$dest" ]] || [[ "$src" -nt "$dest" ]]; then
                cp "$src" "$dest" || return 1
            fi
        fi
    done
    
    # Symlink the profiles directory (contains PeterProfile with settings)
    local profile_src="$CURSOR_CONFIG_SRC/profiles"
    local profile_dest="$CURSOR_CONFIG_DEST/profiles"
    
    if [[ -d "$profile_src" ]]; then
        # Backup existing profiles directory if it's not a symlink
        if [[ -d "$profile_dest" ]] && [[ ! -L "$profile_dest" ]]; then
            local backup_dir
            backup_dir="${profile_dest}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$profile_dest" "$backup_dir" || return 1
            echo "Backed up existing profiles to $backup_dir"
        fi
        
        # Remove existing symlink if it's pointing to the wrong place
        if [[ -L "$profile_dest" ]]; then
            local current_target
            current_target=$(readlink -f "$profile_dest")
            local expected_target
            expected_target=$(readlink -f "$profile_src")
            if [[ "$current_target" != "$expected_target" ]]; then
                rm "$profile_dest"
            fi
        fi
        
        # Create the symlink if it doesn't exist
        if [[ ! -L "$profile_dest" ]]; then
            ln -sf "$profile_src" "$profile_dest" || return 1
        fi
    fi
    
    # Explicitly do NOT sync these directories (let Cursor manage them locally):
    # - globalStorage/ - machine-specific state, SQLite databases
    # - workspaceStorage/ - workspace-specific caches
    # - History/ - local file edit history
    # - extensions.json (root) - has absolute paths to extensions
}

if cursor_config_correct; then
    print_skip "Cursor config already symlinked"
else
    step "Configuring Cursor with PeterProfile" setup_cursor_config
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
