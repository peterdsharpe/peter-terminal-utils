# @name: eza
# @description: Install eza - modern ls replacement (via Scoop)
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-ScoopPackage "eza" "eza (modern ls)"
