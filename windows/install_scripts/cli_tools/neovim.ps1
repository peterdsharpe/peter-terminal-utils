# @name: Neovim
# @description: Install Neovim and link configuration
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-WingetPackage "Neovim.Neovim" "Neovim"
Update-SessionPath

# Link init.vim from Linux dotfiles (cross-platform config)
if (Test-CommandExists "nvim") {
    $nvimConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
    $nvimInitTarget = Join-Path $nvimConfigDir "init.vim"
    $nvimInitSource = Join-Path $PSScriptRoot "../../../linux/dotfiles/init.vim"

    if (Test-Path $nvimInitSource) {
        if (-not (Test-Path $nvimConfigDir)) {
            New-Item -ItemType Directory -Path $nvimConfigDir -Force | Out-Null
        }

        if (Test-Path $nvimInitTarget) {
            Write-Skip "Neovim config already exists at $nvimInitTarget"
        } else {
            if ($script:DryRun) {
                Write-Info "[DRY RUN] Would copy init.vim to $nvimInitTarget"
            } else {
                Write-Step "Copying init.vim to Neovim config directory"
                Copy-Item $nvimInitSource $nvimInitTarget -Force
                Write-Success "Neovim config installed"
            }
        }
    }
}
