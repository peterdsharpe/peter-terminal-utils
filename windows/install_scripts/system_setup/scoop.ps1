# @name: Scoop Package Manager
# @description: Install Scoop and add required buckets
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (-not $script:InstallScoop) {
    Write-Skip "Scoop (disabled by user)"
    return
}

if (Test-CommandExists "scoop") {
    Write-Skip "Scoop already installed"
} else {
    if ($script:DryRun) {
        Write-Info "[DRY RUN] Would install Scoop"
    } else {
        Write-Step "Installing Scoop"
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            Write-Success "Scoop installed"
        } catch {
            Write-Failure "Failed to install Scoop: $_"
            return
        }
    }
}

# Add buckets
if (Test-CommandExists "scoop") {
    foreach ($bucket in @("extras", "nerd-fonts")) {
        $buckets = scoop bucket list 2>$null
        if ($buckets -match $bucket) {
            Write-Skip "Scoop bucket '$bucket' already added"
        } else {
            if ($script:DryRun) {
                Write-Info "[DRY RUN] Would add Scoop bucket '$bucket'"
            } else {
                Write-Step "Adding Scoop bucket '$bucket'"
                scoop bucket add $bucket 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Scoop bucket '$bucket' added"
                } else {
                    Write-Failure "Failed to add Scoop bucket '$bucket'"
                }
            }
        }
    }
}
