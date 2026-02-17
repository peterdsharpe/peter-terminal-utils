# @name: Git
# @description: Install Git and configure settings, aliases, LFS
. "$PSScriptRoot/../../_common.ps1"
Initialize-Standalone

# Install Git
Install-WingetPackage "Git.Git" "Git"
Update-SessionPath

if (-not (Test-CommandExists "git")) {
    Write-Failure "Git not available after install, skipping configuration"
    return
}

if ($script:DryRun) {
    Write-Info "[DRY RUN] Would configure git settings"
    return
}

Write-Step "Configuring git"

# User identity
if ($script:GitName) {
    git config --global user.name $script:GitName
}
if ($script:GitEmail) {
    git config --global user.email $script:GitEmail
}

# Core settings
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global push.autoSetupRemote true
git config --global fetch.prune true
if (Test-CommandExists "nvim") {
    git config --global core.editor "nvim"
}

# Aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate"
git config --global alias.amend "commit --amend --no-edit"
git config --global alias.last "log -1 HEAD --stat"
git config --global alias.unstage "reset HEAD --"

# Merge/rebase
git config --global merge.conflictstyle diff3
git config --global rebase.autoStash true

# LFS
if (Test-CommandExists "git-lfs") {
    git lfs install --force 2>$null
}

Write-Success "Git configured"
