# @name: MiKTeX
# @description: Install MiKTeX TeX distribution
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "MiKTeX.MiKTeX" "MiKTeX"
