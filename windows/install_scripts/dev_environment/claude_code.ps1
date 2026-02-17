# @name: Claude Code
# @description: Install Claude Code CLI via npm
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (-not (Test-CommandExists "npm")) {
    Write-Skip "Claude Code (npm not available - install Node.js first)"
    return
}

if (Test-CommandExists "claude") {
    Write-Skip "Claude Code already installed"
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would install Claude Code"
    return
}

Write-Step "Installing Claude Code"
$output = npm install -g @anthropic-ai/claude-code 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Claude Code installed"
} else {
    Write-Failure "Failed to install Claude Code"
}
