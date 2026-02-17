# Windows Setup

Peter Sharpe's Windows environment setup, mirroring the functionality of `linux/setup`.

## Quick Start

Open PowerShell and run:

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

Or with options:

```powershell
# Preview without making changes
powershell -ExecutionPolicy Bypass -File setup.ps1 -DryRun

# Skip GUI apps and Scoop
powershell -ExecutionPolicy Bypass -File setup.ps1 -NoGui -NoScoop

# Non-interactive (use defaults from config.toml)
powershell -ExecutionPolicy Bypass -File setup.ps1 -NonInteractive
```

## What It Installs

### System Setup
- **Scoop** package manager (for tools not in winget) + `extras` and `nerd-fonts` buckets
- **SSH key** generation (ed25519)
- **SSH Agent** service configuration

### Git Setup
- **Git** with full configuration (aliases, merge/rebase settings, LFS)
- **GitHub CLI** (gh), **GitLab CLI** (glab), **lazygit**
- **delta** diff viewer with git pager integration

### CLI Tools
- **ripgrep** (rg), **fd**, **bat**, **eza**, **fzf**, **zoxide**
- **Neovim** with shared init.vim from linux/dotfiles
- **jq**, **bottom** (btm), **fastfetch**, **ShellCheck**

### Fonts
- **FiraCode Nerd Font** and **Symbols Nerd Font** via Scoop

### Development Environment
- **Node.js** LTS, **uv** (Python), **Rust** (rustup)
- **Python tools** via uv: ruff, ty, httpie, pre-commit, yt-dlp, rich-cli, jupyterlab
- **Cursor IDE** with PeterProfile (shared settings from linux/dotfiles)
- **Claude Code**, **Docker Desktop**, **MiKTeX**

### Shell Setup
- **Oh My Posh** prompt theme (equivalent of Powerlevel10k on Linux)
- **PSReadLine** with predictive IntelliSense, **Terminal-Icons**
- **PowerShell profile** with aliases, tool init, and fzf integration
- **Windows Terminal** settings (font, color scheme)

### Desktop Applications
- Windows Terminal, Firefox, Obsidian, Signal, VLC, LibreOffice, Inkscape, Steam, Zotero

## File Structure

```
windows/
├── setup.ps1              Main orchestrator
├── _common.ps1            Shared utility library
├── config.toml            User settings (git identity)
├── dotfiles/
│   ├── profile.ps1        PowerShell profile (aliases, tool init)
│   ├── ohmyposh.toml      Oh My Posh prompt theme
│   └── windows_terminal.json  Terminal settings reference
└── install_scripts/
    ├── system_setup/      Scoop, SSH
    ├── git_setup/         Git, gh, glab, lazygit, delta
    ├── cli_tools/         rg, fd, bat, eza, fzf, zoxide, nvim, etc.
    ├── fonts/             FiraCode + Symbols Nerd Font
    ├── dev_environment/   Node, uv, Rust, Cursor, Docker, etc.
    ├── shell_setup/       Oh My Posh, PSReadLine, profile, terminal
    └── desktop_apps/      GUI apps via winget
```

## PowerShell Profile

The `dotfiles/profile.ps1` provides:

- **Prompt**: Oh My Posh powerline theme (directory, git status, exit code, execution time)
- **Modern CLI aliases**: `ls`/`ll`/`lt` -> eza, `cat` -> bat, `grep` -> rg, `find` -> fd, `vim` -> nvim
- **Git aliases**: `gs`, `gd`, `ga`, `gc`, `gp`, `gl`, `gpl`, `gco`, `gb`, `gst`
- **Navigation**: `..`, `...`, `....`, `home`
- **Tool init**: zoxide (smart cd), fzf (Ctrl+R history search), fnm (Node version manager)
- **PSReadLine**: Predictive IntelliSense, history search with up/down arrows
- **Utilities**: `mkcd`, `touch`, `which`, `serve`, `myip`
- **WSL**: `wsl-home`, `wsl-here`
- **Local overrides**: Sources `~/.profile_local.ps1` if present

## Package Managers

| Manager | Role | Installs |
|---------|------|----------|
| **winget** (built-in) | Primary | Most tools and apps |
| **Scoop** (optional) | Secondary | eza, delta, bottom, shellcheck, fonts |

## Shared Configuration

These files are shared with the Linux setup (cross-platform):

- **Neovim config**: `linux/dotfiles/init.vim` (copied to `%LOCALAPPDATA%\nvim\init.vim`)
- **Cursor PeterProfile**: `linux/dotfiles/cursor-config/PeterProfile/` (settings.json, keybindings.json)
- **Cursor extensions**: `linux/dotfiles/cursor-config/extensions.txt`

## Post-Setup

1. **Restart terminal** to load the new PowerShell profile
2. **Authenticate GitHub CLI**: `gh auth login`
3. **Windows Terminal**: Font should auto-configure; verify "FiraCode Nerd Font Mono" is set
4. **Docker Desktop**: Log out and back in, then start Docker Desktop
5. **Cursor IDE**: Verify PeterProfile settings were applied
6. [Activation](https://massgrave.dev)
7. [Debloat](https://github.com/ChrisTitusTech/winutil)

## Requirements

- Windows 10 version 1903+ or Windows 11
- winget (App Installer from Microsoft Store)
- PowerShell 5.1+ (built-in) or PowerShell 7+
- Administrator privileges recommended (for SSH Agent service, some installs)
