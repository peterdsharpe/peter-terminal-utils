#!/bin/bash
[[ "${_SOURCED:-}" ]] || exec "$(dirname "$0")/../../_runner.sh" "$0"
# Install snap applications

# Check if snaps are enabled (via INSTALL_SNAPS env var or standalone prompt)
if [[ "${INSTALL_SNAPS:-}" != "Y" ]]; then
    if [[ "${ORCHESTRATED:-}" == "true" ]]; then
        print_skip "Snap installations disabled"
        exit 0
    else
        if ! prompt_yn "Install snap applications? [Y/n]" "Y"; then
            print_skip "Snap installations disabled"
            exit 0
        fi
    fi
fi

install_snap_apps() {
    step_start "Installing snap applications"
    run sudo snap install obsidian --classic
    run sudo snap install zotero-snap
    run sudo snap install code --classic
    run sudo snap install firefox
    run sudo snap install inkscape
    run sudo snap install libreoffice
    run sudo snap install steam
    step_end
    
    # Set Firefox as default browser (must be done after Firefox is installed)
    if [[ "$HEADLESS" == "N" ]] && command -v xdg-settings &> /dev/null; then
        step "Setting Firefox as default browser" xdg-settings set default-web-browser firefox_firefox.desktop
    fi
}

require_sudo "Snap applications" install_snap_apps

