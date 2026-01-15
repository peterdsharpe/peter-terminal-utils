#!/bin/bash
# @name: RustDesk
# @description: Open-source remote desktop client from GitHub releases
# @requires: sudo
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "RustDesk"

# WSL: use Windows RustDesk instead
if is_wsl; then
    print_skip "RustDesk (use Windows version in WSL)"
    exit 0
fi

# Check if already installed
if command -v rustdesk &>/dev/null; then
    print_skip "RustDesk already installed"
    exit 0
fi

# Check for supported package manager
if [[ "$PKG_MANAGER" == "unknown" ]]; then
    print_skip "RustDesk (unsupported package manager)"
    exit 0
fi

# Map architecture (RustDesk uses aarch64, not arm64)
case "$ARCH" in
    x86_64) rd_arch="x86_64" ;;
    arm64)  rd_arch="aarch64" ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

install_rustdesk() {
    local version pkg_name pkg_url tmpdir
    
    # Get latest version from GitHub
    version=$(github_latest_version "rustdesk/rustdesk") || {
        print_error "Failed to get latest RustDesk version"
        return 1
    }
    
    # Determine package name based on package manager
    case "$PKG_MANAGER" in
        apt)
            pkg_name="rustdesk-${version}-${rd_arch}.deb"
            ;;
        dnf)
            pkg_name="rustdesk-${version}-0.${rd_arch}.rpm"
            ;;
        zypper)
            pkg_name="rustdesk-${version}-0.${rd_arch}-suse.rpm"
            ;;
        pacman)
            pkg_name="rustdesk-${version}-0-${rd_arch}.pkg.tar.zst"
            ;;
        *)
            print_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    pkg_url="https://github.com/rustdesk/rustdesk/releases/download/${version}/${pkg_name}"
    
    # Create temp directory and ensure cleanup
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT
    
    step_start "Installing RustDesk ${version}"
    
    # Download package
    run curl -fsSL -o "${tmpdir}/${pkg_name}" "$pkg_url"
    
    # Install based on package manager
    case "$PKG_MANAGER" in
        apt)
            run sudo apt install -y "${tmpdir}/${pkg_name}"
            ;;
        dnf)
            run sudo dnf install -y "${tmpdir}/${pkg_name}"
            ;;
        zypper)
            run sudo zypper install -y --allow-unsigned-rpm "${tmpdir}/${pkg_name}"
            ;;
        pacman)
            run sudo pacman -U --noconfirm "${tmpdir}/${pkg_name}"
            ;;
    esac
    
    step_end
}

require_sudo "RustDesk" install_rustdesk
