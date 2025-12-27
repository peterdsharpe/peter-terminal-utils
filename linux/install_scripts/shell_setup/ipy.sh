#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Set up global ipy Python environment

# Get the linux directory (where ipy folder is relative to)
LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

print_step "Syncing ipy Python environment"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}ℹ${NC} [DRY RUN] uv sync --project $LINUX_DIR/../ipy"
else
    if uv sync --project "$LINUX_DIR/../ipy"; then
        print_success "Synced ipy Python environment"
    else
        print_error "Failed to sync ipy Python environment"
        SCRIPT_FAILED=true
    fi
fi

step "Symlinking ipy command" ln -sf "$LINUX_DIR/../ipy/IPy.sh" "$HOME/.local/bin/ipy"

