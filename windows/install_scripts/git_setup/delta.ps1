# @name: delta
# @description: Install delta diff viewer and configure git pager
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

Install-ScoopPackage "delta" "delta (git diff pager)"
Update-SessionPath

if (Test-CommandExists "delta") {
    if ($script:DryRun) {
        Write-Info "[DRY RUN] Would configure git to use delta"
        return
    }

    Write-Step "Configuring git to use delta"
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.side-by-side true
    Write-Success "Git delta integration configured"
}
