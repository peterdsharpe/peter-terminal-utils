#!/bin/bash
# @name: Switch User Shortcut
# @description: Super+U keyboard shortcut for fast user switching
# @headless: skip
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

skip_if_headless "Switch user shortcut"
skip_if_not_gnome "Switch user shortcut"

# Configuration
BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/switch-user/"
BINDING_NAME="Switch User"
BINDING_COMMAND="gdmflexiserver"
BINDING_KEY="<Super>u"

# Add custom keybinding for fast user switching
# Handles appending to existing keybindings list without clobbering
configure_switch_user_shortcut() {
    local schema="org.gnome.settings-daemon.plugins.media-keys"
    local binding_schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH"
    
    ### Step 1: Get current keybindings list
    local current_bindings
    current_bindings=$(gsettings get "$schema" custom-keybindings) || return 1
    
    ### Step 2: Check if our binding already exists (idempotency)
    if [[ "$current_bindings" == *"$BINDING_PATH"* ]]; then
        print_info "Keybinding path already registered, updating properties"
    else
        ### Step 3: Append our path to the list
        local new_bindings
        if [[ "$current_bindings" == "@as []" ]]; then
            # Empty list - create new array with just our path
            new_bindings="['$BINDING_PATH']"
        else
            # Non-empty list - append to existing array
            # Remove trailing ] and add our path
            new_bindings="${current_bindings%]}, '$BINDING_PATH']"
        fi
        gsettings set "$schema" custom-keybindings "$new_bindings" || return 1
    fi
    
    ### Step 4: Set binding properties
    gsettings set "$binding_schema" name "$BINDING_NAME" || return 1
    gsettings set "$binding_schema" command "$BINDING_COMMAND" || return 1
    gsettings set "$binding_schema" binding "$BINDING_KEY" || return 1
}

step "Configuring Super+U shortcut for user switching" configure_switch_user_shortcut
