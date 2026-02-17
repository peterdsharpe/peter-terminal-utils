# @name: SSH Key
# @description: Generate ed25519 SSH key pair
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

$sshDir = Join-Path $env:USERPROFILE ".ssh"
$keyPath = Join-Path $sshDir "id_ed25519"

if (Test-Path $keyPath) {
    Write-Skip "SSH key already exists"
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would generate SSH key pair"
    return
}

Write-Step "Generating SSH key pair"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

$email = if ($script:GitEmail) { $script:GitEmail } else { "$env:USERNAME@$env:COMPUTERNAME" }
$output = ssh-keygen -t ed25519 -C $email -f $keyPath -N '""' 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "SSH key pair generated at $keyPath"
} else {
    Write-Failure "Failed to generate SSH key pair"
}
