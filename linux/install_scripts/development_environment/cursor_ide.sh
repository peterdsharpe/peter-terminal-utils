#!/bin/bash
# @name: Cursor IDE
# @description: Full Cursor IDE with PeterProfile configuration
# @depends: bootstrap.sh
# @headless: skip
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
    
    _CURSOR_API_CACHE=$(curl -sL --connect-timeout 30 --max-time 60 \
        "https://cursor.com/api/download?platform=${platform}&releaseTrack=stable" 2>/dev/null)
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
    curl -fL --connect-timeout 30 --max-time 3600 --progress-bar \
        "$download_url" -o "$appimage_path" || return 1
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
    curl -fL --connect-timeout 30 --max-time 3600 --progress-bar \
        "$deb_url" -o "$tmp_deb" || { rm -f "$tmp_deb"; return 1; }
    
    pkg_install_local "$tmp_deb"
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
MimeType=text/plain;
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

# Create a profile directly in storage.json (no GUI required)
# Returns the new profile ID
create_profile_directly() {
    local profile_name="$1"
    local profile_id
    
    # Generate a unique 8-character hex ID (similar to what Cursor uses)
    profile_id=$(head -c 4 /dev/urandom | xxd -p)
    
    # Ensure directories exist
    mkdir -p "$CURSOR_CONFIG_DEST/globalStorage"
    mkdir -p "$CURSOR_CONFIG_DEST/profiles/$profile_id"
    
    # Initialize storage.json if it doesn't exist
    if [[ ! -f "$STORAGE_JSON" ]]; then
        echo '{}' > "$STORAGE_JSON"
    fi
    
    # Add the profile to userDataProfiles array
    # Handle case where userDataProfiles doesn't exist yet
    local tmp_file="${STORAGE_JSON}.tmp"
    jq --arg name "$profile_name" --arg loc "$profile_id" \
        'if .userDataProfiles then
            .userDataProfiles += [{"name": $name, "location": $loc}]
         else
            .userDataProfiles = [{"name": $name, "location": $loc}]
         end' \
        "$STORAGE_JSON" > "$tmp_file" && mv "$tmp_file" "$STORAGE_JSON"
    
    echo "$profile_id"
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
    
    # Auto-create profile if it doesn't exist
    if [[ -z "$profile_id" ]]; then
        echo "Creating $PROFILE_NAME profile..."
        profile_id=$(create_profile_directly "$PROFILE_NAME")
        
        if [[ -n "$profile_id" ]]; then
            echo "Created $PROFILE_NAME with ID: $profile_id"
        else
            echo "Failed to create profile in storage.json" >&2
            return 1
        fi
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
# This script installs missing extensions automatically via cursor CLI.

EXTENSIONS_FILE="$CURSOR_CONFIG_SRC/extensions.txt"

# Get list of installed extension IDs (lowercase for case-insensitive comparison)
# Uses --profile to check the correct profile's extensions
get_installed_extensions() {
    cursor --profile "$PROFILE_NAME" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' || true
}

# Check if all extensions from extensions.txt are installed
extensions_need_install() {
    [[ ! -f "$EXTENSIONS_FILE" ]] && return 1  # No extensions file = nothing to install
    
    # cursor command must exist
    if ! command -v cursor &>/dev/null; then
        return 0  # Need to install (will show appropriate warning)
    fi
    
    local installed
    installed=$(get_installed_extensions)
    
    while IFS= read -r ext || [[ -n "$ext" ]]; do
        # Skip empty lines and comments
        [[ -z "$ext" || "$ext" =~ ^[[:space:]]*# ]] && continue
        
        # Check if this extension is installed (case-insensitive)
        local ext_lower="${ext,,}"
        if ! echo "$installed" | grep -qxF "$ext_lower"; then
            return 0  # At least one extension missing
        fi
    done < "$EXTENSIONS_FILE"
    
    return 1  # All extensions installed
}

# Install extensions from extensions.txt, skipping already-installed ones
install_cursor_extensions() {
    if [[ ! -f "$EXTENSIONS_FILE" ]]; then
        echo "Extensions file not found: $EXTENSIONS_FILE"
        return 1
    fi
    
    # Check if cursor command is available
    if ! command -v cursor &>/dev/null; then
        echo "Cursor CLI not found in PATH. Ensure Cursor is installed and ~/.local/bin is in PATH."
        echo "You may need to restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 1
    fi
    
    # Get currently installed extensions
    local installed
    installed=$(get_installed_extensions)
    
    local to_install=()
    local already_installed=0
    local total_in_file=0
    
    # Read extensions.txt and categorize
    while IFS= read -r ext || [[ -n "$ext" ]]; do
        # Skip empty lines and comments
        [[ -z "$ext" || "$ext" =~ ^[[:space:]]*# ]] && continue
        ((total_in_file++))
        
        local ext_lower="${ext,,}"
        if echo "$installed" | grep -qxF "$ext_lower"; then
            ((already_installed++))
        else
            to_install+=("$ext")
        fi
    done < "$EXTENSIONS_FILE"
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo "All $already_installed extensions already installed"
        return 0
    fi
    
    echo "Installing ${#to_install[@]} extensions ($already_installed already present)..."
    
    local failed=()
    local succeeded=0
    
    for ext in "${to_install[@]}"; do
        echo "  Installing: $ext"
        # Capture output and exit code separately (pipe would mask exit code)
        # Use --profile to install to the correct profile
        local output
        output=$(cursor --profile "$PROFILE_NAME" --install-extension "$ext" --force 2>&1)
        local exit_code=$?
        
        # Show output indented
        if [[ -n "$output" ]]; then
            echo "$output" | sed 's/^/    /'
        fi
        
        if [[ $exit_code -eq 0 ]]; then
            ((succeeded++))
        else
            failed+=("$ext")
            echo "    Warning: Failed to install $ext (exit code: $exit_code)"
        fi
    done
    
    echo "Installed $succeeded/${#to_install[@]} extensions"
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "Failed extensions: ${failed[*]}"
        echo "These may be unavailable in the marketplace or require manual installation."
        # Return success anyway - partial installation is acceptable
        # The user can re-run the script later to retry
    fi
    
    return 0
}

if [[ -f "$EXTENSIONS_FILE" ]]; then
    if extensions_need_install; then
        step "Installing Cursor extensions" install_cursor_extensions
    else
        print_skip "All Cursor extensions already installed"
    fi
fi

###############################################################################
### Export Extensions (bidirectional sync)
###############################################################################

# Export all installed extensions back to extensions.txt
# This ensures the file stays in sync with what's actually installed
export_extensions() {
    if ! command -v cursor &>/dev/null; then
        echo "Cursor CLI not available, skipping extension export"
        return 0
    fi
    
    local installed
    installed=$(cursor --profile "$PROFILE_NAME" --list-extensions 2>/dev/null | sort -f)
    
    if [[ -z "$installed" ]]; then
        echo "No extensions installed or failed to query"
        return 0
    fi
    
    local count
    count=$(echo "$installed" | wc -l)
    
    # Check if file would change
    if [[ -f "$EXTENSIONS_FILE" ]]; then
        local current
        current=$(sort -f "$EXTENSIONS_FILE" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -v '^#')
        if [[ "$installed" == "$current" ]]; then
            echo "extensions.txt already up to date ($count extensions)"
            return 0
        fi
    fi
    
    # Write the new file
    echo "$installed" > "$EXTENSIONS_FILE"
    echo "Exported $count extensions to extensions.txt"
}

# Always export after install to keep extensions.txt in sync
step "Syncing extensions.txt" export_extensions

###############################################################################
### Generate Portable Profile Export
###############################################################################

# Generate PeterProfile.code-profile from source files
# This creates a portable export that can be imported via Cursor's UI
generate_code_profile() {
    local src_dir="$CURSOR_CONFIG_SRC/$PROFILE_NAME"
    local output_file="$CURSOR_CONFIG_SRC/PeterProfile.code-profile"
    local settings_file="$src_dir/settings.json"
    local keybindings_file="$src_dir/keybindings.json"
    
    # Verify source files exist
    if [[ ! -f "$settings_file" ]]; then
        echo "Settings file not found: $settings_file"
        return 1
    fi
    if [[ ! -f "$keybindings_file" ]]; then
        echo "Keybindings file not found: $keybindings_file"
        return 1
    fi
    
    # Build extensions array from installed extensions
    local extensions_array="[]"
    local extensions_dir="$HOME/.cursor/extensions"
    
    if [[ -d "$extensions_dir" ]]; then
        # Build array from extension package.json files
        extensions_array=$(
            for ext_dir in "$extensions_dir"/*/; do
                [[ -d "$ext_dir" ]] || continue
                local pkg="$ext_dir/package.json"
                [[ -f "$pkg" ]] || continue
                
                # Extract extension ID and display name
                jq -c '{
                    identifier: {id: "\(.publisher).\(.name)"},
                    displayName: .displayName,
                    applicationScoped: false
                }' "$pkg" 2>/dev/null
            done | jq -s 'unique_by(.identifier.id) | sort_by(.identifier.id)'
        ) || extensions_array="[]"
    fi
    
    # Build the complete profile JSON
    # Use --rawfile to read settings/keybindings and properly escape for JSON
    jq -n \
        --arg name "$PROFILE_NAME" \
        --arg icon "rocket" \
        --rawfile settings "$settings_file" \
        --rawfile keybindings "$keybindings_file" \
        --argjson extensions "$extensions_array" \
        '{
            name: $name,
            icon: $icon,
            settings: $settings,
            keybindings: $keybindings,
            extensions: $extensions,
            globalState: "{}"
        }' > "$output_file" || return 1
    
    local ext_count
    ext_count=$(echo "$extensions_array" | jq 'length')
    echo "Generated PeterProfile.code-profile with $ext_count extensions"
}

step "Generating portable profile export" generate_code_profile

print_success "Cursor IDE setup complete"
