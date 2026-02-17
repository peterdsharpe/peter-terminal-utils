# @name: bat
# @description: Install bat - cat with syntax highlighting
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "sharkdp.bat" "bat"
