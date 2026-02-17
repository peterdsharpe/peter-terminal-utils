# Peter's Windows Setup - Shared Utility Library
# Sourced by all install scripts and setup.ps1
# Equivalent of linux/_common.sh

$ErrorActionPreference = "Continue"

###############################################################################
# Global State
###############################################################################

if (-not (Test-Path variable:script:DryRun))    { $script:DryRun = $false }
if (-not (Test-Path variable:script:Orchestrated)) { $script:Orchestrated = $false }
if (-not (Test-Path variable:script:InstallGui))   { $script:InstallGui = $true }
if (-not (Test-Path variable:script:InstallScoop)) { $script:InstallScoop = $true }
if (-not (Test-Path variable:script:GitName))    { $script:GitName = "" }
if (-not (Test-Path variable:script:GitEmail))   { $script:GitEmail = "" }
if (-not (Test-Path variable:script:ScriptDir))  { $script:ScriptDir = $PSScriptRoot }
if (-not (Test-Path variable:script:FailCount))  { $script:FailCount = 0 }

###############################################################################
# Status Output
###############################################################################

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Blue
    Write-Host "  $Message" -ForegroundColor Blue
    Write-Host "===============================================================================" -ForegroundColor Blue
}

function Write-Step {
    param([string]$Message)
    Write-Host "> " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Skip {
    param([string]$Message)
    Write-Host "[--] " -ForegroundColor Yellow -NoNewline
    Write-Host "$Message (skipped)"
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[XX] " -ForegroundColor Red -NoNewline
    Write-Host $Message
    $script:FailCount++
}

function Write-Info {
    param([string]$Message)
    Write-Host "[ii] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[!!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

###############################################################################
# Command / Admin Detection
###############################################################################

function Test-CommandExists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

###############################################################################
# Package Installation (Idempotent)
###############################################################################

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )
    if (-not $DisplayName) { $DisplayName = $PackageId }

    if (-not (Test-CommandExists "winget")) {
        Write-Failure "$DisplayName (winget not available)"
        return $false
    }

    # Check if already installed
    $listed = winget list --id $PackageId --accept-source-agreements 2>$null
    if ($listed -match [regex]::Escape($PackageId)) {
        Write-Skip "$DisplayName already installed"
        return $true
    }

    if ($script:DryRun) {
        Write-Info "[DRY RUN] Would install $DisplayName"
        return $true
    }

    Write-Step "Installing $DisplayName"
    $output = winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$DisplayName installed"
        return $true
    } else {
        Write-Failure "Failed to install $DisplayName"
        return $false
    }
}

function Install-ScoopPackage {
    param(
        [string]$Package,
        [string]$DisplayName,
        [string]$Bucket = ""
    )
    if (-not $DisplayName) { $DisplayName = $Package }

    if (-not $script:InstallScoop) {
        Write-Skip "$DisplayName (Scoop disabled)"
        return $false
    }

    if (-not (Test-CommandExists "scoop")) {
        Write-Skip "$DisplayName (Scoop not available)"
        return $false
    }

    # Check if already installed
    $list = scoop list $Package 2>$null
    if ($list -match $Package) {
        Write-Skip "$DisplayName already installed"
        return $true
    }

    if ($script:DryRun) {
        Write-Info "[DRY RUN] Would install $DisplayName via Scoop"
        return $true
    }

    Write-Step "Installing $DisplayName via Scoop"
    $installTarget = if ($Bucket) { "$Bucket/$Package" } else { $Package }
    $output = scoop install $installTarget 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$DisplayName installed"
        return $true
    } else {
        Write-Failure "Failed to install $DisplayName"
        return $false
    }
}

###############################################################################
# Config Reading
###############################################################################

function Read-ConfigToml {
    param([string]$Path)

    $config = @{}
    if (-not (Test-Path $Path)) { return $config }

    $currentSection = ""
    foreach ($line in Get-Content $Path) {
        $line = $line.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { continue }

        if ($line -match '^\[(.+)\]$') {
            $currentSection = $Matches[1]
            continue
        }

        if ($line -match '^(\w+)\s*=\s*"(.+)"$') {
            $key = if ($currentSection) { "$currentSection.$($Matches[1])" } else { $Matches[1] }
            $config[$key] = $Matches[2]
        }
    }
    return $config
}

###############################################################################
# Script Runner
###############################################################################

function Invoke-InstallScript {
    param(
        [string]$Path,
        [string]$DisplayName = ""
    )
    if (-not $DisplayName) { $DisplayName = [System.IO.Path]::GetFileNameWithoutExtension($Path) }

    if (-not (Test-Path $Path)) {
        Write-Failure "$DisplayName - script not found: $Path"
        return
    }

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        . $Path
        $sw.Stop()
    } catch {
        Write-Failure "$DisplayName - $_"
    }
}

###############################################################################
# Standalone Init
###############################################################################

function Initialize-Standalone {
    if ($script:Orchestrated) { return }

    # Read config
    $configPath = Join-Path $PSScriptRoot "../config.toml"
    if (-not (Test-Path $configPath)) {
        $configPath = Join-Path $PSScriptRoot "../../config.toml"
    }
    if (Test-Path $configPath) {
        $config = Read-ConfigToml $configPath
        if ($config["user.git_name"])  { $script:GitName  = $config["user.git_name"] }
        if ($config["user.git_email"]) { $script:GitEmail = $config["user.git_email"] }
    }
}

###############################################################################
# PATH Refresh
###############################################################################

function Update-SessionPath {
    # Refresh PATH from registry to pick up newly installed tools
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$userPath;$machinePath"
}
