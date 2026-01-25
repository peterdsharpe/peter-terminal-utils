#!/bin/bash
# @name: Avahi mDNS
# @description: mDNS hostname resolution and SSH service advertisement for LAN discovery
# @requires: sudo
# @depends: ssh_service.sh
# @locks: pkg
source "$(dirname "${BASH_SOURCE[0]}")/../../_common.sh"
standalone_init

###############################################################################
### Install Avahi and mDNS packages
###############################################################################

install_avahi_packages() {
    local packages=(
        avahi-daemon      # mDNS/DNS-SD daemon
        avahi-utils       # avahi-browse, avahi-resolve, etc.
        libnss-mdns       # NSS plugin for mDNS hostname resolution
    )

    step_start "Installing Avahi mDNS packages"
    # shellcheck disable=SC2086
    run pkg_install ${packages[*]}
    step_end
}

###############################################################################
### Configure systemd-resolved to avoid port 5353 conflict
###############################################################################
# Both systemd-resolved and avahi-daemon want port 5353.
# Setting MulticastDNS=resolve lets systemd-resolved resolve .local names
# without binding to the multicast port (leaving it for Avahi).

configure_resolved() {
    local resolved_conf_d="/etc/systemd/resolved.conf.d"
    local drop_in="$resolved_conf_d/avahi-compat.conf"

    # Use drop-in to avoid modifying the main config file
    step_start "Configuring systemd-resolved for Avahi compatibility"
    run sudo mkdir -p "$resolved_conf_d"
    
    # Create drop-in config
    if sudo tee "$drop_in" > /dev/null << 'EOF'
# Allow Avahi to handle mDNS on port 5353
# systemd-resolved will still resolve .local names via Avahi
[Resolve]
MulticastDNS=resolve
EOF
    then
        run sudo systemctl restart systemd-resolved
    fi
    step_end
}

###############################################################################
### Configure nsswitch.conf for mDNS hostname resolution
###############################################################################
# Add mdns4_minimal to the hosts line so .local names resolve via Avahi.
# Using mdns4 (not mdns) avoids IPv6 timeouts on IPv4-only networks.

configure_nsswitch() {
    local nsswitch="/etc/nsswitch.conf"
    
    step_start "Configuring nsswitch.conf for mDNS"
    
    # Check if mdns is already configured
    if grep -q 'mdns' "$nsswitch" 2>/dev/null; then
        print_info "mDNS already configured in nsswitch.conf"
    else
        # Backup original
        run sudo cp "$nsswitch" "${nsswitch}.bak"
        
        # Insert mdns4_minimal before dns in the hosts line
        # Original: hosts: files dns
        # Result:   hosts: files mdns4_minimal [NOTFOUND=return] dns
        run sudo sed -i 's/^\(hosts:.*\)dns/\1mdns4_minimal [NOTFOUND=return] dns/' "$nsswitch"
    fi
    step_end
}

###############################################################################
### Advertise SSH service via Avahi
###############################################################################
# Copy the SSH service file so other machines can discover this host.
# The service file uses %h to advertise the machine's hostname.

setup_ssh_service() {
    local service_dir="/etc/avahi/services"
    local service_file="$service_dir/ssh.service"
    local example_file="/usr/share/doc/avahi-daemon/examples/ssh.service"

    step_start "Setting up SSH service advertisement"
    
    if [[ -f "$service_file" ]]; then
        print_info "SSH service already advertised"
    elif [[ -f "$example_file" ]]; then
        # Use the example file from avahi-daemon package
        run sudo cp "$example_file" "$service_file"
    else
        # Create the service file manually
        sudo tee "$service_file" > /dev/null << 'EOF'
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h</name>
  <service>
    <type>_ssh._tcp</type>
    <port>22</port>
  </service>
</service-group>
EOF
    fi
    step_end
}

###############################################################################
### Enable and start Avahi daemon
###############################################################################

enable_avahi() {
    step "Enabling Avahi daemon" sudo systemctl enable --now avahi-daemon
}

###############################################################################
### Main
###############################################################################

main() {
    install_avahi_packages
    configure_resolved
    configure_nsswitch
    setup_ssh_service
    enable_avahi
    
    print_info "mDNS configured. You can now use hostnames like 'ssh user@hostname.local'"
    print_info "Discover SSH hosts on your LAN with: avahi-browse -r -t _ssh._tcp"
}

require_sudo "Avahi mDNS setup" main
