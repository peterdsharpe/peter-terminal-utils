# @name: fzf
# @description: Install fzf - fuzzy finder
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "junegunn.fzf" "fzf"
