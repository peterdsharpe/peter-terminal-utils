#!/bin/bash
# Runner script for install scripts - provides environment setup
# This script is called by the one-line trampoline in each install script
# when running standalone (not orchestrated by setup.sh)

set -euo pipefail

RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
source "$RUNNER_DIR/_common.sh"

# Initialize for standalone execution (prompts for missing config)
standalone_init

# Mark as sourced so the trampoline in the target script is skipped
export _SOURCED=1

# Source and execute the target script
source "$1"

