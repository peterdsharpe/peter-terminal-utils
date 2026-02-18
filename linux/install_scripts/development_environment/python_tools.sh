#!/bin/bash
# @name: Python Tools
# @description: ruff, ty, jupyterlab, pre-commit, yt-dlp via uv
# @depends: uv.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

step_start "Installing Python tools"
run uv tool install ruff        # Fast linter/formatter
run uv tool install ty          # Type checker
run uv tool install turm        # TUI for Slurm job management
run uv tool install httpie      # Better HTTP client (http/https commands)
run uv tool install pre-commit  # Git hooks for code quality
run uv tool install yt-dlp      # Video downloader
run uv tool install rich-cli    # Pretty terminal output (rich command)
run uv tool install docling     # PDF to text/markdown for LLM input
run uv tool install jupyterlab  # Jupyter notebooks
run uv tool install turm        # TUI for Slurm job management
run uv tool upgrade --all       # Upgrade all tools to latest
step_end

