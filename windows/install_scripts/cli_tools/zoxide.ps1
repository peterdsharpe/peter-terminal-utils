# @name: zoxide
# @description: Install zoxide - smarter cd replacement
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "ajeetdsouza.zoxide" "zoxide"
