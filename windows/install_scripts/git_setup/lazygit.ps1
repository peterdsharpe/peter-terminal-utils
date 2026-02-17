# @name: lazygit
# @description: Install lazygit terminal UI for git
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "JesseDuffield.lazygit" "lazygit"
