* All installation scripts in `./linux/install_scripts` should be executable (chmod +x) and have the correct shebang.
* Error messages should always include actionable context. Never just say "X failed" - explain what was happening, what went wrong, and ideally what to do about it.

## Repository Structure

```
linux/
├── setup               # Python 3 curses TUI orchestrator
├── _common.sh          # Shared bash utilities (source this in every script)
├── config.toml         # User config (git name/email, presets)
├── install_scripts/
│   ├── manifest.conf   # Script execution order and grouping
│   └── <category>/     # One directory per manifest section
│       └── *.sh        # Individual install scripts
├── dotfiles/           # Shell configs (.zshrc, .bashrc, .shell_common, etc.)
└── docs/               # Supplementary documentation
windows/
├── setup.bat           # Main Windows setup (interactive batch)
├── profile.ps1         # PowerShell profile
└── cmdrc.bat           # CMD aliases
ipy/                    # Custom IPython environment with scientific stack
```

## Script Metadata Format

Every install script must start with metadata comments in the first 10 lines:

```bash
#!/bin/bash
# @name: Display Name
# @description: Brief one-line description of what this installs
# @repo: owner/repo                # Optional: GitHub repository
# @depends: bootstrap.sh, other.sh # Optional: comma-separated dependencies
# @requires: sudo                  # Optional: "sudo" if elevated access needed
# @resource: network               # Optional: "network", "cpu", or "mixed"
# @locks: pkg                      # Optional: exclusive locks (pkg, gitconfig, fonts)
# @parallel: true                  # Optional: can run concurrently (default: false)
# @headless: skip                  # Optional: "skip" to skip in headless/WSL mode
```

**Required fields:** `@name`, `@description`
**Recommended fields:** `@depends` (at minimum `bootstrap.sh`), `@resource`

## Manifest Rules (`manifest.conf`)

* **Section names MUST match directory names exactly** (1:1 mapping). `[CLI Tools]` → `cli_tools/`.
* Scripts are listed as relative paths: `category/script.sh`.
* Execution order matters: scripts run top-to-bottom within each section.
* Dependencies declared via `@depends` in scripts take precedence over manifest order.

## Writing a New Install Script

### Minimal template (GitHub tool via binary release):

```bash
#!/bin/bash
# @name: tool-name
# @description: What this tool does
# @repo: owner/repo
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

ensure_github_tool "owner/repo" "tool-name"
```

`ensure_github_tool` handles version checking, architecture detection, download, and install to `~/.local/bin`.

### Template for package-manager installs:

```bash
#!/bin/bash
# @name: tool-name
# @description: What this tool does
# @depends: bootstrap.sh
# @requires: sudo
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

install_tool() {
    pkg_install package-name
}

require_sudo "Tool Name" install_tool
```

### Template for custom installer scripts:

```bash
#!/bin/bash
# @name: tool-name
# @description: What this tool does
# @depends: bootstrap.sh
# @resource: network
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

_run_installer() { fetch -fsSL https://example.com/install.sh | bash; }

if ! command -v tool-name &>/dev/null; then
    step "Installing Tool Name" _run_installer
else
    print_skip "Tool Name already installed"
fi
```

## Key Helper Functions (`_common.sh`)

| Function | Purpose |
|----------|---------|
| `ensure_github_tool REPO TOOL [BINARY] [STRIP] [INSTALLED_NAME] [DL_TYPE]` | Install/update from GitHub releases with version checking |
| `ensure_git_repo URL DEST [NAME]` | Clone or pull a git repository |
| `ensure_command NAME CMD INSTALL_FUNC [sudo]` | Install non-GitHub tool if missing |
| `ensure_gnome_extension UUID [NAME]` | Install/update GNOME Shell extension |
| `pkg_install PACKAGES...` | Cross-distro package install (apt/dnf/pacman/zypper) |
| `pkg_name APT_NAME` | Map package names across distros |
| `require_sudo MSG FUNC` | Run function only if sudo is available |
| `fetch [CURL_OPTIONS...] URL` | curl wrapper with retry and timeout defaults |
| `step MSG CMD...` | Run command with status output (✓/✗) |
| `step_start MSG` / `run CMD` / `step_end` | Grouped commands with status |
| `skip_if_headless NAME` | Exit script in headless/WSL mode |
| `skip_if_not_gnome NAME` | Exit script if not GNOME desktop |
| `get_installed_version BINARY` | Extract semver from `--version` output |
| `semver_compare V1 V2` | Compare versions (returns 0=equal, 1=less, 2=greater) |
| `github_latest_version REPO` | Get latest release version from GitHub |
| `print_skip` / `print_info` / `print_warning` / `print_error` | Colored status output |

## Conventions

* **Idempotent by default:** Always check `command -v` before installing. Use `print_skip` when already installed.
* **Best-effort execution:** Step failures log but don't abort. Use `step ... || exit 1` only for critical steps.
* **Network downloads:** Always use `fetch` (not raw `curl`) for retry/timeout resilience.
* **Cross-distro:** Use `pkg_install`, `pkg_name`, and `$PKG_MANAGER` case statements. Never hardcode apt.
* **Architecture:** Use `$ARCH` (x86_64 or arm64) and `get_release_arch` for GitHub release naming.
* **Naming:** Script filenames use `snake_case.sh`. Functions use `snake_case`. Private helpers use `_prefix`.
* **Standalone mode:** Every script must call `standalone_init` after sourcing `_common.sh`. This lets scripts run independently outside the orchestrator.
* **Adding to known tools:** When adding a new GitHub tool, also add its architecture mapping to `get_release_arch()` and URL pattern to `_get_known_release_url()` in `_common.sh`.
