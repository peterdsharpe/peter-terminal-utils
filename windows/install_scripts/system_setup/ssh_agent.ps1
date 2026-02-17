# @name: SSH Agent
# @description: Enable Windows OpenSSH Agent service and add key
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (-not (Test-IsAdmin)) {
    Write-Warn "SSH Agent service configuration requires administrator privileges"
    Write-Info "Run 'Get-Service ssh-agent | Set-Service -StartupType Automatic; Start-Service ssh-agent' as admin"
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would enable SSH Agent service"
    return
}

Write-Step "Enabling SSH Agent service"
try {
    $agent = Get-Service ssh-agent -ErrorAction SilentlyContinue
    if ($null -eq $agent) {
        Write-Failure "OpenSSH Agent service not found (install OpenSSH from Windows Settings)"
        return
    }

    if ($agent.StartType -ne "Automatic") {
        Set-Service -Name ssh-agent -StartupType Automatic
    }

    if ($agent.Status -ne "Running") {
        Start-Service ssh-agent
    }

    Write-Success "SSH Agent service enabled and running"

    # Add default key if present
    $keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519"
    if (Test-Path $keyPath) {
        $keys = ssh-add -l 2>$null
        if ($keys -notmatch "id_ed25519") {
            ssh-add $keyPath 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "SSH key added to agent"
            }
        } else {
            Write-Skip "SSH key already in agent"
        }
    }
} catch {
    Write-Failure "Failed to configure SSH Agent: $_"
}
