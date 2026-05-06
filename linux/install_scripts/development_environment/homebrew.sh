#!/bin/bash
# @name: Homebrew
# @description: Homebrew package manager for Linux (formerly Linuxbrew)
# @repo: Homebrew/brew
# @depends: bootstrap.sh, build_tools.sh
# @requires: sudo
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

### Locate brew binary across PATH and the two supported install prefixes.
### Default prefix /home/linuxbrew/.linuxbrew is required for bottle support
### per https://docs.brew.sh/Homebrew-on-Linux. The ~/.linuxbrew alt-prefix
### is the legacy single-user location still recognized by Homebrew docs.
_find_brew() {
    if command -v brew &>/dev/null; then
        command -v brew
    elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        echo "/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        echo "$HOME/.linuxbrew/bin/brew"
    fi
}

### Run the official installer in unattended mode.
### NONINTERACTIVE=1 is the documented env var checked at the top of install.sh
### to skip the prompt-and-pause step. The installer uses sudo internally to
### create /home/linuxbrew/.linuxbrew and chown it to the current user.
_run_brew_installer() {
    fetch -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
        | NONINTERACTIVE=1 /bin/bash
}

install_homebrew() {
    ### Linux build deps from docs.brew.sh/Homebrew-on-Linux#requirements that
    ### aren't already installed by bootstrap.sh (git, curl, ca-certificates)
    ### or build_tools.sh (build-essential).
    step_start "Installing Homebrew build dependencies"
    run pkg_install "$(pkg_name procps)" "$(pkg_name file)"
    step_end

    if [[ -z "$(_find_brew)" ]]; then
        step "Installing Homebrew" _run_brew_installer
    else
        print_skip "Homebrew already installed ($(_find_brew))"
    fi
}

require_sudo "Homebrew" install_homebrew

### Activate brew in the current process so the update/upgrade steps below can
### find it (and so any subsequent install scripts in the same orchestrator
### run inherit a working PATH/MANPATH/INFOPATH/HOMEBREW_* environment).
brew_bin="$(_find_brew)"
if [[ -n "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
    step "Updating brew formulae index" brew update
    step "Upgrading installed brew formulae" brew upgrade
else
    print_warning "brew not found after install; skipping update/upgrade"
fi
