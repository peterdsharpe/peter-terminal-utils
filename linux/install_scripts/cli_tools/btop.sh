#!/bin/bash
# @name: btop
# @description: Resource monitor with NVIDIA GPU support (compiled from source)
# @repo: aristocratos/btop
# @depends: bootstrap.sh, build_tools.sh
# @requires: sudo
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

REPO="aristocratos/btop"
INSTALL_PREFIX="$HOME/.local"

# Check if btop has GPU support enabled
has_gpu_support() {
    command -v btop &>/dev/null || return 1
    btop --version 2>&1 | grep -q "GPU_SUPPORT=true"
}

# Skip if already installed with GPU support and up-to-date
if has_gpu_support; then
    needs_github_update "$REPO" "btop" || exit 0
fi

# Requires sudo for setcap (CPU wattage monitoring)
if [[ "${HAS_SUDO:-false}" == false ]]; then
    print_skip "btop (requires sudo for setcap)"
    exit 0
fi

# Install build dependency (lowdown is needed for man page generation)
step "Installing lowdown" pkg_install lowdown

# Clone and build in temporary directory
tmpdir=$(mktemp -d)
step_start "Building btop with GPU support"
run git clone --depth 1 "https://github.com/${REPO}.git" "$tmpdir/btop"
cd "$tmpdir/btop" || { rm -rf "$tmpdir"; exit 1; }
run make GPU_SUPPORT=true -j"$(nproc)"
run make PREFIX="$INSTALL_PREFIX" install
run sudo make PREFIX="$INSTALL_PREFIX" setcap
step_end
result=$?

# Cleanup
rm -rf "$tmpdir"
exit $result
