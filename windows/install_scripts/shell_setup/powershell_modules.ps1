# @name: PowerShell Modules
# @description: Install PSReadLine (latest) and Terminal-Icons
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would install PowerShell modules"
    return
}

# PSReadLine (latest version with predictive IntelliSense)
$psrl = Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($psrl -and $psrl.Version -ge [version]"2.3.0") {
    Write-Skip "PSReadLine already up to date ($($psrl.Version))"
} else {
    Write-Step "Installing/updating PSReadLine"
    try {
        Install-Module PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser -AllowPrerelease 2>$null
        if (-not $?) {
            Install-Module PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
        }
        Write-Success "PSReadLine installed"
    } catch {
        Write-Failure "Failed to install PSReadLine: $_"
    }
}

# Terminal-Icons (file/folder icons in ls output)
if (Get-Module Terminal-Icons -ListAvailable) {
    Write-Skip "Terminal-Icons already installed"
} else {
    Write-Step "Installing Terminal-Icons"
    try {
        Install-Module Terminal-Icons -Force -Scope CurrentUser
        Write-Success "Terminal-Icons installed"
    } catch {
        Write-Failure "Failed to install Terminal-Icons: $_"
    }
}
