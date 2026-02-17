# @name: Desktop Applications
# @description: Install GUI applications via winget
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (-not $script:InstallGui) {
    Write-Skip "GUI application installation disabled"
    return
}

Install-WingetPackage "Microsoft.WindowsTerminal" "Windows Terminal"
Install-WingetPackage "Mozilla.Firefox" "Firefox"
Install-WingetPackage "Obsidian.Obsidian" "Obsidian"
Install-WingetPackage "OpenWhisperSystems.Signal" "Signal"
Install-WingetPackage "VideoLAN.VLC" "VLC"
Install-WingetPackage "TheDocumentFoundation.LibreOffice" "LibreOffice"
Install-WingetPackage "Inkscape.Inkscape" "Inkscape"
Install-WingetPackage "Valve.Steam" "Steam"
Install-WingetPackage "Zotero.Zotero" "Zotero"
