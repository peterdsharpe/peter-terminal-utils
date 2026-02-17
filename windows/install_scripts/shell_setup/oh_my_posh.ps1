# @name: Oh My Posh
# @description: Install Oh My Posh prompt theme engine and custom theme
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "JanDeDobbeleer.OhMyPosh" "Oh My Posh"
Update-SessionPath

# Copy custom theme to Oh My Posh config directory
$themeSource = Join-Path $PSScriptRoot "../../dotfiles/ohmyposh.toml"
$themeDir = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"

if (-not (Test-Path $themeDir)) {
    # Fallback: use POSH_THEMES_PATH or ~/.config/oh-my-posh
    $themeDir = if ($env:POSH_THEMES_PATH) { $env:POSH_THEMES_PATH } else { Join-Path $env:USERPROFILE ".config\oh-my-posh" }
}

if ((Test-Path $themeSource) -and (Test-Path (Split-Path $themeDir -Parent))) {
    if (-not (Test-Path $themeDir)) {
        New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
    }

    $themeDest = Join-Path $themeDir "peter.toml"
    if ($script:DryRun) {
        Write-Info "[DRY RUN] Would copy Oh My Posh theme to $themeDest"
    } else {
        Write-Step "Installing Oh My Posh theme"
        Copy-Item $themeSource $themeDest -Force
        Write-Success "Oh My Posh theme installed"
    }
}
