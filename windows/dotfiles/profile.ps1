# Peter's PowerShell Profile
# Sourced from peter-terminal-utils/windows/dotfiles/profile.ps1
# Equivalent of linux/dotfiles/.shell_common + .zshrc
# Managed by peter-terminal-utils - do not edit directly

###############################################################################
# Oh My Posh (prompt theme - equivalent of Powerlevel10k)
###############################################################################

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Use custom theme if available, otherwise fall back to built-in
    $peterTheme = Join-Path $PSScriptRoot "ohmyposh.toml"
    if (Test-Path $peterTheme) {
        oh-my-posh init pwsh --config $peterTheme | Invoke-Expression
    } else {
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
    }
}

###############################################################################
# PSReadLine Configuration
###############################################################################

if (Get-Module PSReadLine -ListAvailable) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -MaximumHistoryCount 50000
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

###############################################################################
# Terminal-Icons (file/folder icons in ls output)
###############################################################################

if (Get-Module Terminal-Icons -ListAvailable) {
    Import-Module Terminal-Icons
}

###############################################################################
# Modern CLI aliases (use modern replacements when available)
###############################################################################

# eza (ls replacement)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls  { eza --icons @args }
    function ll  { eza -la --icons --git @args }
    function la  { eza -a --icons @args }
    function lt  { eza -la --icons --tree --level=2 @args }
} else {
    function ll  { Get-ChildItem -Force @args }
}

# bat (cat replacement)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat --paging=never @args }
}

# ripgrep (grep replacement)
if (Get-Command rg -ErrorAction SilentlyContinue) {
    Set-Alias grep rg
}

# fd (find replacement)
if (Get-Command fd -ErrorAction SilentlyContinue) {
    Set-Alias find fd
}

# neovim (vim replacement)
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vim nvim
    Set-Alias vi nvim
}

###############################################################################
# Git aliases
###############################################################################

function gs  { git status @args }
function gd  { git diff @args }
function ga  { git add @args }
function gc  { git commit @args }
function gp  { git push @args }
function gl  { git log --oneline -20 @args }
function gpl { git pull @args }
function gco { git checkout @args }
function gb  { git branch @args }
function gst { git stash @args }

###############################################################################
# Navigation
###############################################################################

function ..    { Set-Location .. }
function ...   { Set-Location ../.. }
function ....  { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function home  { Set-Location $HOME }

###############################################################################
# Environment variables
###############################################################################

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $env:EDITOR = "nvim"
    $env:VISUAL = "nvim"
}

###############################################################################
# Tool initializations
###############################################################################

# zoxide (smarter cd)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# fzf (fuzzy finder)
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # Ctrl+R: fzf history search
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        $line = (Get-History | Select-Object -ExpandProperty CommandLine | fzf --tac --no-sort)
        if ($line) {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line)
        }
    }

    # Use fd for fzf if available (faster, respects .gitignore)
    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
        $env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
        $env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --follow --exclude .git'
    }
}

# fnm (fast node manager)
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

###############################################################################
# Utility functions
###############################################################################

function mkcd {
    param([string]$dir)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

function touch {
    param([string]$file)
    if (Test-Path $file) {
        (Get-Item $file).LastWriteTime = Get-Date
    } else {
        New-Item $file -ItemType File | Out-Null
    }
}

function which {
    param([string]$cmd)
    (Get-Command $cmd -ErrorAction SilentlyContinue).Source
}

function serve { python -m http.server @args }

function myip {
    (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content.Trim()
}

###############################################################################
# WSL integration
###############################################################################

function wsl-home { wsl --cd ~ }
function wsl-here { wsl --cd (Get-Location) }

###############################################################################
# Local overrides
###############################################################################

# Source machine-specific config if present
# Create this file for any per-machine customization
$localProfile = Join-Path $HOME ".profile_local.ps1"
if (Test-Path $localProfile) {
    . $localProfile
}
