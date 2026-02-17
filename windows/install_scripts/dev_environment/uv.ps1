# @name: uv
# @description: Install uv Python package manager
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (Test-CommandExists "uv") {
    Write-Skip "uv already installed"
    if (-not $script:DryRun) {
        Write-Step "Updating uv"
        uv self update 2>$null
        Write-Success "uv updated"
    }
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would install uv"
    return
}

Write-Step "Installing uv"
try {
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
    Write-Success "uv installed"
} catch {
    Write-Failure "Failed to install uv: $_"
}
Update-SessionPath
