# Windows Setup

Peter Sharpe's Windows environment setup scripts, mirroring the functionality of `linux/setup.sh`.

## Quick Start

### Full Windows Setup

Run as Administrator (right-click → Run as administrator):

```batch
setup.bat
```

This will:
- Install CLI tools (git, gh, ripgrep, fd, bat, fzf, eza, zoxide, lazygit, neovim, etc.)
- Install development tools (uv, Rust, Docker Desktop, Cursor)
- Install GUI applications (VS Code, Obsidian, Signal, Firefox, etc.)
- Install Nerd Fonts (FiraCode, Symbols)
- Configure git with aliases and delta integration
- Generate SSH key pair
- Set up PowerShell and CMD profiles

### WSL Setup

After running `setup.bat`, set up WSL with Ubuntu:

```batch
setup_wsl.bat
```

This will:
- Install WSL2 with Ubuntu (requires restart on first install)
- Run `linux/setup.sh` inside WSL to configure your Linux environment
- Configure Windows/WSL integration

## Files

| File | Description |
|------|-------------|
| `setup.bat` | Main Windows setup script (interactive) |
| `setup_wsl.bat` | WSL2/Ubuntu bootstrap script |
| `profile.ps1` | PowerShell profile with aliases and tool initializations |
| `cmdrc.bat` | CMD profile with Linux-like aliases |
| `cmdrc_install.bat` | Installs cmdrc.bat as CMD AutoRun |
| `uv_install.bat` | Standalone uv installer (also in setup.bat) |

## PowerShell Profile

The `profile.ps1` provides:

- **Modern CLI aliases**: `ls`/`ll` → eza, `cat` → bat
- **Git aliases**: `gs`, `gd`, `ga`, `gc`, `gp`, `gl`, etc.
- **Navigation**: `..`, `...`, `home`, `desktop`, `github`
- **Tool initialization**: zoxide, fzf, fnm
- **Utility functions**: `mkcd`, `touch`, `serve`, `myip`, `weather`
- **WSL integration**: `wsl-home`, `wsl-here`

The profile is automatically sourced when you run `setup.bat`.

### Manual Installation

If you prefer to install manually:

```powershell
# Create profile directory if needed
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force

# Add sourcing line to your profile
Add-Content $PROFILE ". 'C:\path\to\peter-terminal-utils\windows\profile.ps1'"
```

## CMD Profile

The `cmdrc.bat` provides Linux-like aliases for Command Prompt:

- `ls`, `ll` → dir
- `clear` → cls
- `cp`, `mv`, `rm` → copy, move, del
- `grep` → findstr
- `cat` → type
- `pwd`, `ps`, `kill`, etc.

Installed automatically by `setup.bat` or manually via `cmdrc_install.bat`.

## Package Managers

The setup uses two package managers:

1. **winget** (built into Windows 11): Primary package manager for most tools
2. **Scoop** (optional): For tools not available in winget (eza, delta, fonts)

## Requirements

- Windows 10 version 1903+ or Windows 11
- winget (App Installer from Microsoft Store)
- Administrator privileges (for some installations)

## Post-Setup

After running the setup:

1. **Authenticate GitHub CLI**:
   ```
   gh auth login
   ```

2. **Configure Windows Terminal**:
   - Set font to "FiraCode Nerd Font" for icons
   - Ubuntu profile should appear automatically after WSL setup

3. **VS Code / Cursor**:
   - Import PeterProfile from https://gist.github.com/peterdsharpe
   - Install WSL extension for Linux development

4. **Docker Desktop**:
   - Log out and back in after installation
   - Start Docker Desktop manually

5. [Activation](https://massgrave.dev)

6. [Debloat](https://github.com/ChrisTitusTech/winutil)