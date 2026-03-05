# Peter's Terminal Utils

Cross-platform scripts for setting up a development environment from scratch on Linux and Windows. Includes shell configuration, CLI tools, dev toolchains, desktop apps, and a custom IPython environment for scientific computing.

## Quick Start

**Linux** (interactive TUI - select tools, presets, and options):

```bash
cd linux
./setup
```

**Windows** (PowerShell):

```powershell
cd windows
powershell -ExecutionPolicy Bypass -File setup.ps1
```

Both setups are idempotent - safe to re-run at any time. They check what's already installed and skip accordingly.

## What Gets Installed

The Linux and Windows setups install a parallel set of tools:

| Category | Tools |
|----------|-------|
| **Git** | git (with aliases, delta pager, LFS), GitHub CLI, GitLab CLI, lazygit |
| **CLI** | fzf, fd, ripgrep, bat, eza, zoxide, neovim, fastfetch, btop/bottom, jq, shellcheck, tldr |
| **Shell** | Zsh + Oh My Zsh + Powerlevel10k (Linux) / PowerShell + Oh My Posh (Windows), shared aliases and tool init |
| **Dev** | uv (Python), Node.js, Rust, Docker, Cursor IDE, Claude Code, TeX Live / MiKTeX |
| **Python tools** | ruff, ty, httpie, pre-commit, yt-dlp, rich-cli, jupyterlab (installed via uv) |
| **Fonts** | FiraCode Nerd Font, Symbols Nerd Font |
| **Desktop apps** | Firefox, Obsidian, Signal, VLC, LibreOffice, Inkscape, Steam, Zotero |

See the [Linux README](linux/README.md) and [Windows README](windows/README.md) for full details.

## Linux Setup

The Linux setup is a Python 3 curses TUI that reads a manifest of install scripts and lets you select which to run. Features:

- **Cross-distro**: Ubuntu, Debian, Mint, Fedora, Arch (auto-detected; uses `pkg_install` abstraction)
- **Presets**: Desktop, Headless, with/without sudo - or manually select individual scripts
- **GNOME customization**: Dark theme, extensions (Dash to Panel, Tiling Assistant), input/window settings, custom wallpaper
- **Parallel execution**: Scripts declare resource locks; independent scripts can run concurrently
- **Standalone scripts**: Every script can be run individually outside the orchestrator

```
./setup --help          # see options
./setup --list          # list available presets
./setup --dry-run       # preview without executing
```

## Windows Setup

The Windows setup is a PowerShell orchestrator using winget (primary) and Scoop (for tools not in winget). Features:

- **Interactive prompts** for git identity, GUI apps, and Scoop usage
- **Non-interactive mode** for unattended installs (`-NonInteractive`)
- **Shared config**: Neovim init, Cursor IDE profile, and extensions are shared with the Linux setup

```powershell
setup.ps1 -DryRun           # preview without executing
setup.ps1 -NoGui            # skip desktop applications
setup.ps1 -NoScoop          # skip Scoop package manager
setup.ps1 -NonInteractive   # use defaults from config.toml
```

## IPy

A custom IPython environment for scientific computing, launched with the `ipy` command. Pre-imports NumPy, SciPy, pandas, SymPy, Matplotlib, Plotly, PyVista, PyTorch, JAX, and [AeroSandbox](https://github.com/peterdsharpe/AeroSandbox). Includes Rich pretty-printing and a WolframAlpha query helper.

```bash
ipy   # starts IPython with the scientific stack pre-loaded
```

Managed by uv; dependencies and environment are defined in [`ipy/pyproject.toml`](ipy/pyproject.toml).

## Repository Structure

```
linux/
├── setup                  Python 3 curses TUI orchestrator
├── _common.sh             Shared bash utilities (cross-distro helpers)
├── config.toml            User config (git name/email, presets)
├── install_scripts/       Individual install scripts, grouped by category
│   └── manifest.conf      Script execution order and grouping
└── dotfiles/              Shell configs (.zshrc, .bashrc, .shell_common, etc.)

windows/
├── setup.ps1              PowerShell orchestrator
├── _common.ps1            Shared PowerShell utilities
├── config.toml            User config (git name/email)
├── install_scripts/       Individual install scripts, grouped by category
└── dotfiles/              PowerShell profile, Oh My Posh theme, terminal settings

ipy/
├── peter_terminal_imports.py   IPython startup script
├── IPy.sh / IPy.bat            Platform launchers
└── pyproject.toml              Dependencies (uv-managed)
```

## Customization

**User config**: Edit `linux/config.toml` or `windows/config.toml` to set your git name and email.

**Local overrides**: Both the Linux and Windows shell configs source a `.local` file if present (`~/.shell_common.local` on Linux, `~/.profile_local.ps1` on Windows), so machine-specific settings stay out of the repo.

## License

MIT
