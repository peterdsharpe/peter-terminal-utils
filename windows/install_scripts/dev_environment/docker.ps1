# @name: Docker Desktop
# @description: Install Docker Desktop
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (Test-CommandExists "docker") {
    Write-Skip "Docker already installed"
    return
}

Install-WingetPackage "Docker.DockerDesktop" "Docker Desktop"

if ($LASTEXITCODE -eq 0 -and -not $script:DryRun) {
    Write-Warn "Log out and back in, then start Docker Desktop to complete setup"
}
