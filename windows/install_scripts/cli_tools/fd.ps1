# @name: fd
# @description: Install fd - fast find alternative
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "sharkdp.fd" "fd"
