# @name: fastfetch
# @description: Install fastfetch - system information tool
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "Fastfetch-cli.Fastfetch" "fastfetch"
