#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Install Python tools via uv

step_start "Installing Python tools"
run ~/.local/bin/uv tool install ruff        # Fast linter/formatter
run ~/.local/bin/uv tool install ty          # Type checker
run ~/.local/bin/uv tool install turm        # TUI for Slurm job management
run ~/.local/bin/uv tool install httpie      # Better HTTP client (http/https commands)
run ~/.local/bin/uv tool install pre-commit  # Git hooks for code quality
run ~/.local/bin/uv tool install yt-dlp      # Video downloader
run ~/.local/bin/uv tool install rich-cli    # Pretty terminal output (rich command)
run ~/.local/bin/uv tool install docling     # PDF to text/markdown for LLM input
run ~/.local/bin/uv tool install jupyterlab  # Jupyter notebooks
run ~/.local/bin/uv tool upgrade --all       # Upgrade all tools to latest
step_end

