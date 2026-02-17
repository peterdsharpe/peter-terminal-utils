# @name: Cursor IDE
# @description: Install Cursor IDE and configure PeterProfile
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "Anysphere.Cursor" "Cursor IDE"
Update-SessionPath

# Install extensions from shared list
$extensionsFile = Join-Path $PSScriptRoot "../../../linux/dotfiles/cursor-config/extensions.txt"
if ((Test-CommandExists "cursor") -and (Test-Path $extensionsFile)) {
    if ($script:DryRun) {
        Write-Info "[DRY RUN] Would install Cursor extensions"
        return
    }

    Write-Step "Installing Cursor extensions"
    $extensions = Get-Content $extensionsFile | Where-Object { $_.Trim() -ne "" }
    foreach ($ext in $extensions) {
        cursor --install-extension $ext 2>$null | Out-Null
    }
    Write-Success "Cursor extensions installed"
}

# Copy PeterProfile settings
$profileSource = Join-Path $PSScriptRoot "../../../linux/dotfiles/cursor-config/PeterProfile"
$cursorUserDir = Join-Path $env:APPDATA "Cursor\User"

if ((Test-Path $profileSource) -and (Test-Path $cursorUserDir)) {
    foreach ($file in @("settings.json", "keybindings.json")) {
        $src = Join-Path $profileSource $file
        $dst = Join-Path $cursorUserDir $file

        if ((Test-Path $src) -and (-not (Test-Path $dst))) {
            if ($script:DryRun) {
                Write-Info "[DRY RUN] Would copy $file to Cursor profile"
            } else {
                Write-Step "Copying $file to Cursor profile"
                Copy-Item $src $dst -Force
                Write-Success "Cursor $file installed"
            }
        } elseif (Test-Path $dst) {
            Write-Skip "Cursor $file already exists"
        }
    }
}
