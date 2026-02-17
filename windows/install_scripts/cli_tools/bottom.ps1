# @name: bottom
# @description: Install bottom (btm) - system monitor (via Scoop)
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-ScoopPackage "bottom" "bottom (btm - system monitor)"
