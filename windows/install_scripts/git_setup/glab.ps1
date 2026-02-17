# @name: GitLab CLI
# @description: Install GitLab CLI (glab)
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "GLab.GLab" "GitLab CLI (glab)"
