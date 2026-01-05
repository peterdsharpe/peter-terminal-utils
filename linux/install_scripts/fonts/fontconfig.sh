#!/bin/bash
# @name: Fontconfig
# @description: Font fallback config for Nerd Font symbols
# @parallel: false
# @locks: fonts
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

configure_fontconfig() {
    mkdir -p ~/.config/fontconfig || return 1
    cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test name="family" qual="any"><string>FiraCode Nerd Font</string></test>
    <edit name="family" mode="append" binding="weak">
      <string>Symbols Nerd Font</string>
    </edit>
  </match>
  <match target="pattern">
    <test name="family" qual="any"><string>FiraCode Nerd Font Mono</string></test>
    <edit name="family" mode="append" binding="weak">
      <string>Symbols Nerd Font Mono</string>
    </edit>
  </match>
</fontconfig>
EOF
}

step "Configuring fontconfig fallback" configure_fontconfig

