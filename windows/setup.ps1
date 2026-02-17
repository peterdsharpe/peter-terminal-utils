#Requires -Version 5.1
# Peter Sharpe's Windows Setup Script
# Equivalent of linux/setup
# Usage: powershell -ExecutionPolicy Bypass -File setup.ps1

param(
    [switch]$DryRun,
    [switch]$NoGui,
    [switch]$NoScoop,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Continue"
$script:ScriptDir = $PSScriptRoot

# Source shared library
. "$ScriptDir\_common.ps1"

###############################################################################
# Banner
###############################################################################

Write-Host ""
Write-Host "+-------------------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "|                     Peter Sharpe's Windows Setup Script                       |" -ForegroundColor Cyan
Write-Host "+-------------------------------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

###############################################################################
# Configuration
###############################################################################

# Read config.toml
$configPath = Join-Path $ScriptDir "config.toml"
$config = Read-ConfigToml $configPath
$script:GitName  = if ($config["user.git_name"])  { $config["user.git_name"] }  else { "Peter Sharpe" }
$script:GitEmail = if ($config["user.git_email"]) { $config["user.git_email"] } else { "peterdsharpe@gmail.com" }

# Interactive prompts (unless -NonInteractive)
if (-not $NonInteractive) {
    if (-not $DryRun) {
        $dryInput = Read-Host "Dry run (preview changes without making them)? [y/N]"
        if ($dryInput -match '^[yY]') { $DryRun = [switch]::Present }
    }

    if (-not $NoGui) {
        $guiInput = Read-Host "Install GUI applications (Firefox, Obsidian, etc.)? [Y/n]"
        if ($guiInput -match '^[nN]') { $NoGui = [switch]::Present }
    }

    if (-not $NoScoop) {
        $scoopInput = Read-Host "Install Scoop package manager (for eza, delta, fonts)? [Y/n]"
        if ($scoopInput -match '^[nN]') { $NoScoop = [switch]::Present }
    }

    $nameInput = Read-Host "Git user name [$($script:GitName)]"
    if ($nameInput) { $script:GitName = $nameInput }

    $emailInput = Read-Host "Git email [$($script:GitEmail)]"
    if ($emailInput) { $script:GitEmail = $emailInput }
}

# Set global state
$script:DryRun       = [bool]$DryRun
$script:InstallGui   = -not [bool]$NoGui
$script:InstallScoop = -not [bool]$NoScoop
$script:Orchestrated = $true

# Check admin
$isAdmin = Test-IsAdmin
if ($isAdmin) {
    Write-Info "Running with administrator privileges"
} else {
    Write-Warn "Running without administrator privileges (some features limited)"
}

Write-Host ""
Write-Info "Configuration: DryRun=$($script:DryRun), GUI=$($script:InstallGui), Scoop=$($script:InstallScoop), Admin=$isAdmin"
Write-Info "Git: $($script:GitName) <$($script:GitEmail)>"

# Check winget
if (-not (Test-CommandExists "winget")) {
    Write-Failure "winget not found. Install App Installer from the Microsoft Store."
    Write-Info "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1"
    exit 1
}
Write-Success "winget is available"

###############################################################################
# Script Execution Order
###############################################################################

$scriptBase = Join-Path $ScriptDir "install_scripts"
$totalSw = [System.Diagnostics.Stopwatch]::StartNew()

# --- System Setup ---
Write-Header "System Setup"
Invoke-InstallScript "$scriptBase\system_setup\scoop.ps1" "Scoop"
Invoke-InstallScript "$scriptBase\system_setup\ssh_key.ps1" "SSH Key"
Invoke-InstallScript "$scriptBase\system_setup\ssh_agent.ps1" "SSH Agent"

# --- Git Setup ---
Write-Header "Git Setup"
Invoke-InstallScript "$scriptBase\git_setup\git.ps1" "Git"
Invoke-InstallScript "$scriptBase\git_setup\github_cli.ps1" "GitHub CLI"
Invoke-InstallScript "$scriptBase\git_setup\glab.ps1" "GitLab CLI"
Invoke-InstallScript "$scriptBase\git_setup\lazygit.ps1" "lazygit"
Invoke-InstallScript "$scriptBase\git_setup\delta.ps1" "delta"

# --- CLI Tools ---
Write-Header "CLI Tools"
Invoke-InstallScript "$scriptBase\cli_tools\ripgrep.ps1" "ripgrep"
Invoke-InstallScript "$scriptBase\cli_tools\fd.ps1" "fd"
Invoke-InstallScript "$scriptBase\cli_tools\bat.ps1" "bat"
Invoke-InstallScript "$scriptBase\cli_tools\eza.ps1" "eza"
Invoke-InstallScript "$scriptBase\cli_tools\fzf.ps1" "fzf"
Invoke-InstallScript "$scriptBase\cli_tools\zoxide.ps1" "zoxide"
Invoke-InstallScript "$scriptBase\cli_tools\neovim.ps1" "Neovim"
Invoke-InstallScript "$scriptBase\cli_tools\jq.ps1" "jq"
Invoke-InstallScript "$scriptBase\cli_tools\bottom.ps1" "bottom"
Invoke-InstallScript "$scriptBase\cli_tools\fastfetch.ps1" "fastfetch"
Invoke-InstallScript "$scriptBase\cli_tools\shellcheck.ps1" "ShellCheck"

# --- Fonts ---
Write-Header "Fonts"
Invoke-InstallScript "$scriptBase\fonts\nerd_fonts.ps1" "Nerd Fonts"

# --- Development Environment ---
Write-Header "Development Environment"
Invoke-InstallScript "$scriptBase\dev_environment\nodejs.ps1" "Node.js"
Invoke-InstallScript "$scriptBase\dev_environment\uv.ps1" "uv"
Invoke-InstallScript "$scriptBase\dev_environment\python_tools.ps1" "Python Tools"
Invoke-InstallScript "$scriptBase\dev_environment\rust.ps1" "Rust"
Invoke-InstallScript "$scriptBase\dev_environment\cursor_ide.ps1" "Cursor IDE"
Invoke-InstallScript "$scriptBase\dev_environment\claude_code.ps1" "Claude Code"
Invoke-InstallScript "$scriptBase\dev_environment\docker.ps1" "Docker"
Invoke-InstallScript "$scriptBase\dev_environment\miktex.ps1" "MiKTeX"

# --- Shell Setup ---
Write-Header "Shell Setup"
Invoke-InstallScript "$scriptBase\shell_setup\oh_my_posh.ps1" "Oh My Posh"
Invoke-InstallScript "$scriptBase\shell_setup\powershell_modules.ps1" "PowerShell Modules"
Invoke-InstallScript "$scriptBase\shell_setup\powershell_profile.ps1" "PowerShell Profile"
Invoke-InstallScript "$scriptBase\shell_setup\windows_terminal.ps1" "Windows Terminal"

# --- Desktop Applications ---
Write-Header "Desktop Applications"
Invoke-InstallScript "$scriptBase\desktop_apps\apps.ps1" "Desktop Apps"

###############################################################################
# Summary
###############################################################################

$totalSw.Stop()
$elapsed = $totalSw.Elapsed

Write-Header "Setup Complete!"
Write-Host ""
Write-Info "Total time: $($elapsed.Minutes)m $($elapsed.Seconds)s"
Write-Host ""

if ($script:FailCount -gt 0) {
    Write-Failure "$($script:FailCount) step(s) had errors - review output above"
    Write-Host ""
}

Write-Success "Next steps:"
Write-Host ""

if (Test-CommandExists "gh") {
    Write-Info "Authenticate GitHub CLI:"
    Write-Host "    gh auth login"
    Write-Host ""
}

Write-Info "Restart your terminal to load the new PowerShell profile"
Write-Host ""

Write-Info "Set Windows Terminal font to 'FiraCode Nerd Font Mono' for icons"
Write-Host ""

Write-Info "Configure Cursor IDE with PeterProfile"
Write-Host ""

if (-not $script:DryRun) {
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
