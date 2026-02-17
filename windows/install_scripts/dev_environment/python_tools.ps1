# @name: Python Tools
# @description: Install Python CLI tools via uv
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (-not (Test-CommandExists "uv")) {
    Write-Skip "Python tools (uv not available)"
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would install Python tools via uv"
    return
}

$tools = @(
    "ruff",
    "ty",
    "httpie",
    "pre-commit",
    "yt-dlp",
    "rich-cli",
    "jupyterlab"
)

Write-Step "Installing Python tools via uv"
foreach ($tool in $tools) {
    $output = uv tool install $tool 2>&1
}
$output = uv tool upgrade --all 2>&1
Write-Success "Python tools installed"
