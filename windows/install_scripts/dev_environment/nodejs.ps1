# @name: Node.js
# @description: Install Node.js LTS
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "OpenJS.NodeJS.LTS" "Node.js LTS"
Update-SessionPath

# Update npm if node is available
if (Test-CommandExists "npm") {
    if (-not $script:DryRun) {
        Write-Step "Updating npm"
        $output = npm install -g npm@latest 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "npm updated"
        }
    }
}
