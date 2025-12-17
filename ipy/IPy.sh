#!/bin/bash
# Global IPython launcher using the peter-terminal-utils/ipy environment
# Works from any directory - pwd is preserved in the IPython session

# Resolve symlinks to get the real script location
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

echo -e "\033]0;Peter's Python Terminal\007"
uv run --project "$SCRIPT_DIR" ipython --no-banner --no-term-title -i "$SCRIPT_DIR/peter_terminal_imports.py"
