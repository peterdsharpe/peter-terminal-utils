# @name: GitHub CLI
# @description: Install GitHub CLI (gh)
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "GitHub.cli" "GitHub CLI (gh)"
