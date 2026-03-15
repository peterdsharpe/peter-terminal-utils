#!/bin/bash
# @name: btop
# @description: Resource monitor with NVIDIA GPU support (compiled from source)
# @repo: aristocratos/btop
# @depends: bootstrap.sh, build_tools.sh
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

# Install build dependency (lowdown is needed for man page generation)
if [[ "${HAS_SUDO:-false}" == true ]]; then
    step "Installing lowdown" pkg_install lowdown
fi

# Detect g++ major version - btop 1.4.6+ requires C++23 (GCC 14+)
GXX_VERSION=$(g++ -dumpversion 2>/dev/null | cut -d. -f1)
if [[ -z "$GXX_VERSION" ]] || (( GXX_VERSION < 14 )); then
    if [[ "${HAS_SUDO:-false}" == false ]]; then
        print_warning "g++ >= 14 needed to compile btop (system has v${GXX_VERSION:-none}); installing prebuilt binary (no GPU monitoring)"
        ensure_github_tool "$REPO" "btop" "btop" 1
        exit $?
    fi
    step "Installing GCC 14 (system g++ is v${GXX_VERSION:-unknown}, need >= 14 for C++23)" \
        pkg_install gcc-14 g++-14
    MAKE_CC="CC=gcc-14"
    MAKE_CXX="CXX=g++-14"
else
    MAKE_CC=""
    MAKE_CXX=""
fi

# Clone and build in temporary directory
tmpdir=$(mktemp -d)
step_start "Building btop with GPU support"
run git clone --depth 1 "https://github.com/${REPO}.git" "$tmpdir/btop"
cd "$tmpdir/btop" || { rm -rf "$tmpdir"; exit 1; }
run make $MAKE_CC $MAKE_CXX GPU_SUPPORT=true -j"$(nproc)"
run make PREFIX="$INSTALL_PREFIX" install
if [[ "${HAS_SUDO:-false}" == true ]]; then
    run sudo make PREFIX="$INSTALL_PREFIX" setcap
else
    print_warning "Skipping setcap (no sudo) - CPU wattage monitoring will be unavailable"
fi
step_end
result=$?

# Cleanup
rm -rf "$tmpdir"
exit $result
