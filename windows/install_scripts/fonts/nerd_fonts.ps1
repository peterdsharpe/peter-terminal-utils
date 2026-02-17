# @name: Nerd Fonts
# @description: Install FiraCode Nerd Font and Symbols Nerd Font via Scoop
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-ScoopPackage "FiraCode-NF" "FiraCode Nerd Font" "nerd-fonts"
Install-ScoopPackage "NerdFontsSymbolsOnly" "Symbols Nerd Font" "nerd-fonts"
