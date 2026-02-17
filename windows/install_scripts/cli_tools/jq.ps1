# @name: jq
# @description: Install jq - JSON processor
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "jqlang.jq" "jq"
