#!/bin/bash
# @name: AppImage Support
# @description: libfuse2 + AppImageLauncher for AppImage desktop integration
# @depends: bootstrap.sh
# @requires: sudo
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "AppImage Support"

###############################################################################
### Install libfuse2 (required for most AppImages to execute)
###############################################################################

# Most AppImages are built against libfuse2. Modern distros ship libfuse3 by
# default, so we need to install the legacy version for AppImage compatibility.

install_libfuse2() {
    case "$PKG_MANAGER" in
        apt)
            # Ubuntu 24.04+ renamed libfuse2 to libfuse2t64 (64-bit time_t transition)
            # Check which package is available
            if apt-cache show libfuse2t64 &>/dev/null; then
                pkg_install libfuse2t64
            else
                pkg_install libfuse2
            fi
            ;;
        dnf)
            pkg_install fuse-libs
            ;;
        pacman)
            pkg_install fuse2
            ;;
        zypper)
            pkg_install libfuse2
            ;;
        *)
            print_error "Unsupported package manager for libfuse2: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Check if libfuse2 is already available (the library, not necessarily the package)
if ldconfig -p 2>/dev/null | grep -q "libfuse.so.2"; then
    print_skip "libfuse2 already installed"
else
    if [[ "${HAS_SUDO:-false}" == true ]]; then
        step "Installing libfuse2" install_libfuse2
    else
        print_skip "libfuse2 (requires sudo)"
    fi
fi

###############################################################################
### Install AppImageLauncher
###############################################################################

# AppImageLauncher intercepts AppImage execution and offers to integrate them
# into the desktop menu. It moves AppImages to ~/Applications and creates
# .desktop entries automatically.
#
# Note: PPAs are deprecated, so we install from GitHub releases directly.
# This means no automatic updates - the script checks versions and updates
# when re-run.
#
# We query the GitHub API to get actual asset URLs because the filename format
# is complex (includes build numbers and commit hashes).

APPIMAGELAUNCHER_REPO="TheAssassin/AppImageLauncher"

# Map architecture for AppImageLauncher releases
get_ail_arch() {
    case "$ARCH" in
        x86_64) echo "amd64" ;;
        arm64)  echo "arm64" ;;
        *)
            print_error "Unsupported architecture for AppImageLauncher: $ARCH"
            return 1
            ;;
    esac
}

# Get installed AppImageLauncher version (extracts semver from dpkg version string)
get_ail_installed_version() {
    if ! command -v dpkg &>/dev/null; then
        return 1
    fi
    
    local full_version
    full_version=$(dpkg -s appimagelauncher 2>/dev/null | grep '^Version:' | awk '{print $2}')
    if [[ -z "$full_version" ]]; then
        return 1
    fi
    
    # Extract semver from version like "2.2.0-travis995.0f91801" -> "2.2.0"
    echo "$full_version" | grep -oP '^\d+\.\d+\.\d+' | head -1
}

# Find the download URL for the .deb package from GitHub releases API
# Returns the browser_download_url for the matching .deb asset
find_ail_deb_url() {
    local ail_arch api_url release_info deb_url
    
    ail_arch=$(get_ail_arch) || return 1
    
    # Query the latest release from GitHub API
    api_url="https://api.github.com/repos/${APPIMAGELAUNCHER_REPO}/releases/latest"
    
    release_info=$(curl -sfL --connect-timeout 10 "$api_url") || {
        echo "Failed to query GitHub API for AppImageLauncher releases" >&2
        return 1
    }
    
    # Find the .deb asset matching our architecture
    # Pattern: appimagelauncher_*_ARCH.deb (works for both old "bionic" and new naming)
    deb_url=$(echo "$release_info" | jq -r --arg arch "$ail_arch" \
        '.assets[] | select(.name | endswith("_" + $arch + ".deb")) | .browser_download_url' \
        | head -1)
    
    if [[ -z "$deb_url" || "$deb_url" == "null" ]]; then
        echo "No matching .deb package found for architecture: $ail_arch" >&2
        return 1
    fi
    
    echo "$deb_url"
}

# Get the version from the latest GitHub release
get_ail_latest_version() {
    local api_url release_info version
    
    api_url="https://api.github.com/repos/${APPIMAGELAUNCHER_REPO}/releases/latest"
    
    release_info=$(curl -sfL --connect-timeout 10 "$api_url") || {
        echo "Failed to query GitHub API" >&2
        return 1
    }
    
    # Extract version from tag_name (e.g., "v2.2.0" -> "2.2.0")
    version=$(echo "$release_info" | jq -r '.tag_name // empty' | sed 's/^v//')
    
    if [[ -z "$version" ]]; then
        echo "Failed to parse version from GitHub release" >&2
        return 1
    fi
    
    echo "$version"
}

install_appimagelauncher() {
    local deb_url pkg_name tmpdir version
    
    # Get the actual download URL from GitHub API
    deb_url=$(find_ail_deb_url) || {
        print_error "Failed to find AppImageLauncher download URL"
        return 1
    }
    
    # Extract filename from URL
    pkg_name=$(basename "$deb_url")
    
    # Extract version for display
    version=$(get_ail_latest_version) || version="latest"
    
    # Create temp directory and ensure cleanup
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    
    step_start "Installing AppImageLauncher ${version}"
    
    # Download package
    run curl -fL --progress-bar -o "${tmpdir}/${pkg_name}" "$deb_url"
    
    if [[ ! -f "${tmpdir}/${pkg_name}" ]]; then
        print_error "Download failed: ${deb_url}"
        step_end
        return 1
    fi
    
    # Install the package
    run pkg_install_local "${tmpdir}/${pkg_name}"
    
    step_end
    
    # Clean up
    rm -rf "$tmpdir"
    trap - EXIT
    
    return "$(step_result)"
}

# Only supported on apt-based distros (AppImageLauncher provides .deb packages)
if [[ "$PKG_MANAGER" != "apt" ]]; then
    print_skip "AppImageLauncher (only available for apt-based distros; libfuse2 installed for manual AppImage use)"
else
    # Check versions and install/update if needed
    check_and_install_appimagelauncher() {
        local installed_version latest_version
        installed_version=$(get_ail_installed_version) || installed_version=""
        latest_version=$(get_ail_latest_version) || {
            print_warning "Cannot check AppImageLauncher version (network?)"
            latest_version=""
        }
        
        if [[ -n "$installed_version" && -n "$latest_version" ]]; then
            semver_compare "$installed_version" "$latest_version"
            case $? in
                0) print_skip "AppImageLauncher at latest ($installed_version)" ;;
                2) print_skip "AppImageLauncher newer than release ($installed_version > $latest_version)" ;;
                1)
                    print_info "AppImageLauncher: $installed_version -> $latest_version"
                    require_sudo "AppImageLauncher update" install_appimagelauncher
                    ;;
            esac
        else
            print_skip "AppImageLauncher already installed"
        fi
    }
    
    if command -v ail-cli &>/dev/null || command -v AppImageLauncher &>/dev/null; then
        check_and_install_appimagelauncher
    else
        require_sudo "AppImageLauncher" install_appimagelauncher
    fi
fi

###############################################################################
### Create ~/Applications directory
###############################################################################

# AppImageLauncher moves integrated AppImages to ~/Applications by default.
# Create this directory proactively so users know where to look.

APPLICATIONS_DIR="$HOME/Applications"

if [[ -d "$APPLICATIONS_DIR" ]]; then
    print_skip "\$HOME/Applications directory exists"
else
    step "Creating ~/Applications directory" mkdir -p "$APPLICATIONS_DIR"
fi

###############################################################################
### Post-install notes
###############################################################################

print_info "AppImage support configured:"
print_info "  - libfuse2: AppImages can now execute"
if command -v ail-cli &>/dev/null || command -v AppImageLauncher &>/dev/null; then
    print_info "  - AppImageLauncher: Double-click any .AppImage to integrate"
    print_info "  - Integrated apps are stored in ~/Applications"
fi