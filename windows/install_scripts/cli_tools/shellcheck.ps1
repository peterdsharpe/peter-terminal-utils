# @name: ShellCheck
# @description: Install ShellCheck - shell script linter (via Scoop)
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-ScoopPackage "shellcheck" "ShellCheck"
