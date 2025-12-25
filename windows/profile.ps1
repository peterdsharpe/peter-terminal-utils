# Peter's PowerShell Profile
# Managed by peter-terminal-utils - mirrors linux/dotfiles/.zshrc
# Source: https://github.com/peterdsharpe/peter-terminal-utils

###############################################################################
### Modern CLI Aliases
###############################################################################

# eza (ls replacement) - if installed
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza --icons @args }
    function ll { eza -la --icons @args }
    function la { eza -a --icons @args }
    function lt { eza --tree --icons @args }
}

# bat (cat replacement) - if installed
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

# fd (find replacement) - already named correctly on Windows

###############################################################################
### Git Aliases
###############################################################################

function gs { git status @args }
function gd { git diff @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git log --oneline -20 @args }
function gco { git checkout @args }
function gbr { git branch @args }
function glg { git log --oneline --graph --decorate @args }

###############################################################################
### Navigation Aliases
###############################################################################

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }

# Quick directory shortcuts
function home { Set-Location $env:USERPROFILE }
function desktop { Set-Location "$env:USERPROFILE\Desktop" }
function downloads { Set-Location "$env:USERPROFILE\Downloads" }
function docs { Set-Location "$env:USERPROFILE\Documents" }
function gh { Set-Location "$env:USERPROFILE\GitHub" }

###############################################################################
### Utility Aliases
###############################################################################

# Clear screen
Set-Alias -Name cls -Value Clear-Host -Option AllScope
Set-Alias -Name clear -Value Clear-Host -Option AllScope

# Which command equivalent
function which { Get-Command @args | Select-Object -ExpandProperty Source }

# Open current directory in explorer
function explorer. { explorer . }
function e. { explorer . }

# Open current directory in VS Code
function code. { code . }
function cursor. { cursor . }

# Reload profile
function reload { . $PROFILE }

# Print PATH nicely
function path { $env:PATH -split ';' | ForEach-Object { $_ } }

###############################################################################
### Environment Variables
###############################################################################

# Set editor (prefer nvim if available)
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $env:EDITOR = "nvim"
    $env:VISUAL = "nvim"
} elseif (Get-Command vim -ErrorAction SilentlyContinue) {
    $env:EDITOR = "vim"
    $env:VISUAL = "vim"
} else {
    $env:EDITOR = "code"
    $env:VISUAL = "code"
}

# Add user-local binaries to PATH
$userLocalBin = "$env:USERPROFILE\.local\bin"
$cargoBin = "$env:USERPROFILE\.cargo\bin"

if (Test-Path $userLocalBin) {
    if ($env:PATH -notlike "*$userLocalBin*") {
        $env:PATH = "$userLocalBin;$env:PATH"
    }
}

if (Test-Path $cargoBin) {
    if ($env:PATH -notlike "*$cargoBin*") {
        $env:PATH = "$cargoBin;$env:PATH"
    }
}

###############################################################################
### History Configuration
###############################################################################

# Set history size
$MaximumHistoryCount = 50000

# PSReadLine configuration for better history
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 50000
    
    # History search with up/down arrows
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    
    # Ctrl+R for reverse history search
    Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    
    # Tab completion like bash/zsh
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    
    # Prediction (if available in PS 7+)
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}

###############################################################################
### Tool Initializations
###############################################################################

# Initialize zoxide (smarter cd) - if installed
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Initialize fzf (fuzzy finder) integration - if installed
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    # PSFzf module for better integration
    if (Get-Module -ListAvailable -Name PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
    
    # Use fd for fzf if available
    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
        $env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
        $env:FZF_ALT_C_COMMAND = 'fd --type d --hidden --follow --exclude .git'
    }
}

# Initialize fnm (Node.js version manager) - if installed
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

###############################################################################
### Prompt Configuration
###############################################################################

# Check for Oh My Posh (the PowerShell equivalent of p10k)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Use a nice theme - adjust path as needed
    $ompTheme = "$env:POSH_THEMES_PATH\powerlevel10k_rainbow.omp.json"
    if (Test-Path $ompTheme) {
        oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
    } else {
        # Fall back to a built-in theme
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\agnoster.omp.json" | Invoke-Expression
    }
} else {
    # Custom minimal prompt if Oh My Posh not installed
    function prompt {
        $path = $ExecutionContext.SessionState.Path.CurrentLocation.Path
        $home = $env:USERPROFILE
        if ($path.StartsWith($home)) {
            $path = "~" + $path.Substring($home.Length)
        }
        
        # Git branch if in a git repo
        $gitBranch = ""
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $branch = git branch --show-current 2>$null
            if ($branch) {
                $gitBranch = " ($branch)"
            }
        }
        
        # Color the prompt
        Write-Host "$path" -NoNewline -ForegroundColor Cyan
        Write-Host "$gitBranch" -NoNewline -ForegroundColor Yellow
        Write-Host " >" -NoNewline -ForegroundColor Green
        return " "
    }
}

###############################################################################
### WSL Integration
###############################################################################

# Quick WSL access
function wsl-home { wsl ~ }
function wsl-here { wsl --cd (Get-Location) }

# Run command in WSL
function wslrun { wsl @args }

###############################################################################
### Helpful Functions
###############################################################################

# Make directory and cd into it
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# Touch command (create empty file or update timestamp)
function touch {
    param([string]$Path)
    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

# Quick HTTP server (requires Python)
function serve {
    param([int]$Port = 8000)
    if (Get-Command python -ErrorAction SilentlyContinue) {
        python -m http.server $Port
    } elseif (Get-Command uv -ErrorAction SilentlyContinue) {
        uv run python -m http.server $Port
    } else {
        Write-Host "Python not found" -ForegroundColor Red
    }
}

# Get public IP
function myip { (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content }

# Weather (requires curl)
function weather {
    param([string]$Location = "")
    if ($Location) {
        curl "wttr.in/$Location"
    } else {
        curl "wttr.in"
    }
}

###############################################################################
### Startup Message
###############################################################################

# Suppress startup message for cleaner terminal
# Uncomment below for a startup greeting:
# Write-Host "PowerShell $($PSVersionTable.PSVersion) | peter-terminal-utils loaded" -ForegroundColor DarkGray

