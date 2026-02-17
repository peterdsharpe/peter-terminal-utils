# @name: PowerShell Profile
# @description: Install/link PowerShell profile to source dotfiles/profile.ps1
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

$sourceProfile = Join-Path $PSScriptRoot "../../dotfiles/profile.ps1"
$sourceProfile = (Resolve-Path $sourceProfile -ErrorAction SilentlyContinue).Path

if (-not $sourceProfile -or -not (Test-Path $sourceProfile)) {
    Write-Failure "Source profile not found"
    return
}

# Determine the PowerShell profile path
# $PROFILE points to CurrentUserCurrentHost profile
$profileDir = Split-Path $PROFILE -Parent

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would configure PowerShell profile at $PROFILE"
    return
}

# Create profile directory if needed
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Check if profile already sources our file
if (Test-Path $PROFILE) {
    $content = Get-Content $PROFILE -Raw
    if ($content -match "peter-terminal-utils") {
        Write-Skip "PowerShell profile already configured"
        return
    }
}

# Add sourcing line to profile
Write-Step "Configuring PowerShell profile"
$sourceLine = ". `"$sourceProfile`""
Add-Content -Path $PROFILE -Value "`n# Peter's terminal utilities (peter-terminal-utils)`n$sourceLine"
Write-Success "PowerShell profile configured to source $sourceProfile"
