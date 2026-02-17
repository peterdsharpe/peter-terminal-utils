# @name: ripgrep
# @description: Install ripgrep (rg) - fast recursive grep
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "BurntSushi.ripgrep.MSVC" "ripgrep (rg)"
