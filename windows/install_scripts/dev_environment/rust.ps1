# @name: Rust
# @description: Install Rust via rustup
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

if (Test-CommandExists "rustup") {
    Write-Skip "Rust already installed"
    if (-not $script:DryRun) {
        Write-Step "Updating Rust toolchain"
        rustup update 2>$null
        Write-Success "Rust updated"
    }
    return
}

Install-WingetPackage "Rustlang.Rustup" "Rust (rustup)"
