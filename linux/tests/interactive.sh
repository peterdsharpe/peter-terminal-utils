#!/bin/bash
# Launch an interactive shell in the test container with the repo mounted.
#
# Usage:
#     sudo ./interactive.sh              # Start interactive bash shell
#     sudo ./interactive.sh --build      # Rebuild image first, then start shell
#
# The repository is mounted read-write at /home/testuser/peter-terminal-utils,
# so any changes made in the container are reflected on the host (and vice versa).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINUX_DIR="$REPO_ROOT/linux"

IMAGE_NAME="peter-terminal-utils-test"
CONTAINER_MOUNT="/home/testuser/peter-terminal-utils"

###############################################################################
### Helpers
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_step() { echo -e "${CYAN}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

###############################################################################
### Main
###############################################################################

# Parse arguments
BUILD_FIRST=false
for arg in "$@"; do
    case "$arg" in
        --build) BUILD_FIRST=true ;;
        --help|-h)
            echo "Usage: $0 [--build]"
            echo "  --build    Rebuild Docker image before starting"
            exit 0
            ;;
        *)
            print_error "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

# Check Docker access
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not accessible. Try running with sudo."
    exit 1
fi

# Build image if requested or if it doesn't exist
if $BUILD_FIRST; then
    print_step "Building Docker image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"
    print_success "Docker image built successfully"
elif ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    print_step "Image not found, building: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"
    print_success "Docker image built successfully"
fi

# Launch interactive container with repo mounted
print_step "Starting interactive container..."
echo -e "  ${CYAN}Repo mount:${NC} $REPO_ROOT → $CONTAINER_MOUNT"
echo -e "  ${CYAN}Working dir:${NC} $CONTAINER_MOUNT/linux"
echo ""

exec docker run -it --rm \
    -v "$REPO_ROOT:$CONTAINER_MOUNT" \
    -e "TERM=${TERM:-xterm-256color}" \
    "$IMAGE_NAME" \
    /bin/bash
