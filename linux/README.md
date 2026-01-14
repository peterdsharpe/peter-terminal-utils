# Peter's Linux Setup Scripts

Interactive TUI for setting up a fresh Linux installation with development tools, shell configuration, and desktop customization.

## Quick Start

```bash
cd linux
./setup
```

## Supported Distributions

| Distro | Package Manager | Desktop | Status |
|--------|-----------------|---------|--------|
| Ubuntu 25.10 | apt | GNOME | **Primary target** - fully tested |
| Ubuntu 24.04+ | apt | GNOME | Supported |
| Debian 12+ | apt | GNOME | Supported |
| Linux Mint | apt | Cinnamon | Supported (GNOME settings skipped) |
| Fedora 39+ | dnf | GNOME | Supported |
| Arch Linux | pacman | GNOME | Supported |
| Kubuntu / KDE Neon | apt | KDE | Partial (GNOME settings skipped) |

### Desktop Environment Support

- **GNOME**: Full support including extensions, settings, and customizations
- **KDE/Plasma**: CLI tools, shell setup, and development tools work; GNOME-specific settings are automatically skipped
- **Cinnamon**: Most features work; some GNOME settings may apply via shared gsettings schemas
- **XFCE/Other**: CLI tools and development environment work; desktop customizations skipped

## What Gets Installed

### CLI Tools (Cross-Distro)
All installed from GitHub releases for latest versions:
- **fzf** - Fuzzy finder
- **fd** - Fast find alternative
- **bat** - Cat with syntax highlighting
- **eza** - Modern ls replacement
- **zoxide** - Smart cd
- **delta** - Git diff viewer
- **bottom/btop** - System monitors
- **lazygit** - Terminal UI for git
- **neovim** - Text editor

### Shell Setup
- **Oh My Zsh** with plugins (zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab)
- **Powerlevel10k** prompt theme
- Custom `.zshrc` with aliases and functions

### Development Tools
- **uv** - Fast Python package manager
- **Rust** via rustup
- **Docker** (official install script)
- **Cursor** IDE

### Desktop Applications
Cross-distro application installation:
- **Flatpak**: Obsidian, VS Code, Firefox, Inkscape, LibreOffice, Steam, Zotero
- **Snap**: Signal (for secure password storage)

### GNOME Customization (GNOME only)
- Dark theme, keyboard repeat settings, touchpad configuration
- Dash to Panel and Just Perfection extensions
- Nemo as default file manager
- Custom desktop background

## Architecture

```
linux/
├── setup              # Main TUI entry point (Python)
├── _common.sh         # Shared utilities for all scripts
├── config.toml        # User configuration (git name/email)
├── install_scripts/   # Individual install scripts
│   ├── system_packages/
│   ├── cli_tools/
│   ├── dev_tools/
│   ├── shell_setup/
│   ├── gnome_settings/
│   ├── gnome_extensions/
│   ├── desktop_apps/
│   └── manifest.conf  # Script ordering and grouping
└── dotfiles/          # Configuration files (.zshrc, etc.)
```

### Adding New Distro Support

1. Update `_common.sh`:
   - Add distro detection in `detect_distro()`
   - Add package manager handling in `pkg_install()`, `pkg_update()`, `pkg_upgrade()`
   - Add package name mappings in `pkg_name()`

2. Test individual scripts that may have distro-specific code

3. Update this README with test results

## Presets

- **Desktop** - Full installation with GUI components
- **Headless** - Server installation, skips GUI packages
- **Desktop (no sudo)** - User-local installs only
- **Headless (no sudo)** - Minimal user-local server setup

## Running Individual Scripts

Scripts can run standalone:

```bash
./install_scripts/cli_tools/bat.sh
```

When run standalone, scripts will prompt for configuration. When run via the TUI, they inherit settings from the orchestrator.
