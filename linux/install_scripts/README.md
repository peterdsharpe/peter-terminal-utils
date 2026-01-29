# Install Scripts

This directory contains modular installation scripts for setting up a Linux system. Scripts are organized by category and executed via the `setup` orchestrator.

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `cli_tools/` | Command-line utilities (bat, fd, ripgrep, etc.) |
| `desktop_applications/` | GUI applications (Flatpak apps, Signal, etc.) |
| `development_environment/` | Dev tools (uv, Rust, Docker, Cursor, etc.) |
| `fonts/` | Font installation and configuration |
| `git_setup/` | Git, GitHub CLI, delta, lazygit |
| `gnome_desktop/` | GNOME desktop settings and customization |
| `gnome_extensions/` | GNOME Shell extensions |
| `lan_interop/` | Local network tools (Avahi, GVFS, croc) |
| `shell_setup/` | Shell configuration (zsh, oh-my-zsh, dotfiles) |
| `system_setup/` | Core system packages and configuration |

## Script Metadata

Each script includes metadata in header comments that controls execution behavior. The orchestrator (`setup`) parses this metadata to determine dependencies, parallelization, and display information.

### Metadata Reference

| Key | Description | Values | Example |
|-----|-------------|--------|---------|
| `@name` | Display name shown in TUI | Any string | `@name: bat` |
| `@description` | Brief description of what the script installs | Any string | `@description: cat with syntax highlighting` |
| `@repo` | GitHub repository (for reference) | `owner/repo` | `@repo: sharkdp/bat` |
| `@depends` | Scripts that must run first | Comma-separated `.sh` filenames | `@depends: bootstrap.sh, ohmyzsh.sh` |
| `@requires` | System requirements | `sudo` | `@requires: sudo` |
| `@resource` | Resource type for concurrency tuning | `network`, `cpu`, `mixed` | `@resource: network` |
| `@locks` | Exclusive resource locks | `pkg`, `gitconfig`, `fonts`, etc. | `@locks: pkg` |
| `@parallel` | Whether script can run in parallel | `true` (default), `false` | `@parallel: false` |
| `@headless` | Behavior in headless/WSL mode | `skip` | `@headless: skip` |

### Metadata Details

#### `@name` and `@description`
Used for display in the TUI. If `@name` is not specified, the script filename is used (with underscores converted to spaces and title-cased).

#### `@depends`
Lists scripts that must complete successfully before this script runs. Dependencies are resolved transitively by the orchestrator. Use the `.sh` filename, not the display name:

```bash
# @depends: bootstrap.sh, ohmyzsh.sh
```

#### `@requires: sudo`
Scripts with this metadata will be skipped when running without sudo privileges. Use with `require_sudo()` wrapper in the script:

```bash
# @requires: sudo
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

setup_function() {
    # ... installation logic requiring sudo ...
}

require_sudo "Script Name" setup_function
```

#### `@resource`
Hints to the orchestrator about what resource the script primarily uses:
- `network` - Downloads from the internet (high parallelism OK)
- `cpu` - CPU-intensive compilation (limited to core count)
- `mixed` - Default, moderate parallelism

#### `@locks`
Prevents scripts with the same lock from running simultaneously. Common locks:
- `pkg` - Package manager operations (apt, dnf, etc.)
- `gitconfig` - Modifying `~/.gitconfig`
- `fonts` - Font cache operations

#### `@parallel`
Set to `false` for scripts that must run sequentially (e.g., modify shared state). Default is `true`.

#### `@headless: skip`
Scripts with this metadata are automatically skipped in headless mode (no display) or WSL. Use with `skip_if_headless()`:

```bash
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init
skip_if_headless "Script Name"
```

## Script Template

New scripts should follow this template:

```bash
#!/bin/bash
# @name: Tool Name
# @description: Brief description of what this installs
# @repo: owner/repo (if GitHub-hosted)
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

# For GitHub tools with standard release binaries:
ensure_github_tool "owner/repo" "tool_name"

# Or for custom installation:
install_tool() {
    # Installation logic here
}
step "Installing tool" install_tool
```

## Common Helpers

The `_common.sh` file provides helpers for common installation patterns:

| Helper | Purpose |
|--------|---------|
| `ensure_github_tool` | Install/update from GitHub releases with version checking |
| `needs_github_update` | Check if GitHub tool needs install/update (for custom installers) |
| `ensure_git_repo` | Clone or update a git repository |
| `ensure_gnome_extension` | Install/update GNOME Shell extension |
| `ensure_command` | Install if command not present (for non-GitHub tools) |
| `pkg_install` | Cross-distro package installation |
| `require_sudo` | Skip gracefully if no sudo |
| `skip_if_headless` | Skip in headless/WSL mode |
| `step` | Execute command with status output |
| `step_start`/`run`/`step_end` | Group multiple commands |

## Manifest

The `manifest.conf` file defines execution order and grouping. Scripts are executed in the order listed. Section names must match directory names exactly.

```ini
[System Setup]
system_setup/bootstrap.sh
system_setup/shell_packages.sh
...

[CLI Tools]
cli_tools/bat.sh
cli_tools/fd.sh
...
```

See `manifest.conf` for the complete execution order.
