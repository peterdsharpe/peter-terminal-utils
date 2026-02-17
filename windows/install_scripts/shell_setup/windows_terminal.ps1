# @name: Windows Terminal Settings
# @description: Apply font and theme settings to Windows Terminal
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

# Windows Terminal settings.json location
$wtSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Also check for Windows Terminal Preview and unpackaged installs
if (-not (Test-Path $wtSettingsPath)) {
    $wtSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
}
if (-not (Test-Path $wtSettingsPath)) {
    $wtSettingsPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json"
}

if (-not (Test-Path $wtSettingsPath)) {
    Write-Skip "Windows Terminal settings not found (is it installed?)"
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would update Windows Terminal settings"
    return
}

Write-Step "Updating Windows Terminal settings"

try {
    # Read current settings (strip comments for JSON parsing)
    $raw = Get-Content $wtSettingsPath -Raw
    $json = $raw -replace '(?m)^\s*//.*$', '' -replace '/\*[\s\S]*?\*/', ''
    $settings = $json | ConvertFrom-Json

    $modified = $false

    # Set default profile font in "defaults" under "profiles"
    if (-not $settings.profiles.defaults) {
        $settings.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue @{} -Force
        $modified = $true
    }
    $defaults = $settings.profiles.defaults

    # Font
    $fontObj = @{
        face = "FiraCode Nerd Font Mono"
        size = 11
    }
    if (-not $defaults.font -or $defaults.font.face -ne "FiraCode Nerd Font Mono") {
        $defaults | Add-Member -NotePropertyName "font" -NotePropertyValue $fontObj -Force
        $modified = $true
    }

    # Color scheme
    if (-not $defaults.colorScheme -or $defaults.colorScheme -ne "One Half Dark") {
        $defaults | Add-Member -NotePropertyName "colorScheme" -NotePropertyValue "One Half Dark" -Force
        $modified = $true
    }

    if ($modified) {
        $settings | ConvertTo-Json -Depth 20 | Set-Content $wtSettingsPath -Encoding UTF8
        Write-Success "Windows Terminal settings updated (font: FiraCode Nerd Font Mono 11pt, theme: One Half Dark)"
    } else {
        Write-Skip "Windows Terminal settings already configured"
    }
} catch {
    Write-Failure "Failed to update Windows Terminal settings: $_"
}
