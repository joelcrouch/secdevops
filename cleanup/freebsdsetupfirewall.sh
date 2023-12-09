#!/bin/sh
# To download this script:
# $ pkg install curl
# $ curl -LO https://gitlab.cecs.pdx.edu/crouchj/secdevops-crouchj/-/blob/main/freebsdsetupfirewall.sh?ref_type=heads
# $ chmod +x freebsdsetupfirewall.sh

#
#The following features are added:
# - switching (internal to the network) via FreeBSD pf
# - DHCP server, DNS server via dnsmasq
# - firewall via FreeBSD pf
# - NAT layer via FreeBSD pf

# Additional Feature:
# - Modify the local SSH server port for management purposes
# - Add snort installation and configuration
# - Add test capabilites via a test script 
# curl -LO https://gitlab.cecs.pdx.edu/crouchj/secdevops-crouchj/-/blob/main/snorttest.sh

# Check if the script is run with superuser privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "Please run this script as root."
   exit 1
fi
# Choose a new SSH port for management purposes
new_ssh_port="2222"

# Modify SSH server configuration to use the new port
if grep -q "^Port $new_ssh_port$" "/etc/ssh/sshd_config"; then
    echo "SSH port is already set to $new_ssh_port."
else
    # Edit the SSH configuration to change the port
    sed -i '' "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config

    # Restart the SSH service to apply changes
    service sshd restart

    echo "SSH port has been set to $new_ssh_port."
fi

# Snort installation and configuration commands go here
freebsd-update fetch
freebsd-update install
pkg update
reboot

mkdir ~/snort_src && cd ~/snort_src

pkg install git flex bison gcc cmake libdnet libpcap hwloc pcre openssl luajit lua51 pkgconf libpcap

wget https://github.com/snort3/libdaq/archive/refs/tags/v3.0.9.tar.gz
tar xf v3.0.9.tar.gz && cd libdaq-3.0.9
pkg install autoconf automake libtool
./bootstrap
./configure
make
make install

# (The rest of your Snort setup commands go here)

#test against default config file
/usr/local/snort/bin/snort -c /usr/local/snort/etc/snort/snort.lua --daq-dir /usr/local/lib/daq

# Configure snort3 to load at boot time
snort3_enable=$(sysrc -n snort3_enable)
if [ "$snort3_enable" = "YES" ]; then
    echo "snort3 is already set to load at boot time."
else
    sysrc snort3_enable="YES"
    echo "snort3 has been configured to load at boot time."
fi

# Custom snort3 Rules
# might want to zip up the .sh file with a snort3_rules file, open it in the same directory, and then have the script read the rules from there?
snort3_rules="
alert tcp any any -> any 2222 (msg:\"SSH connection attempt\"; sid:100001;)
alert icmp any any -> any any (msg:\"ICMP traffic detected\"; sid:100002;)"
# Add more custom rules here

# Check if local.rules file exists
if [ -f /usr/local/etc/snort3/rules/local.rules ]; then
    echo "local.rules already exists."
else
    # If it doesn't exist, create the local.rules file
    touch /usr/local/etc/snort3/rules/local.rules
    echo "local.rules has been created."
fi

# Path to the local.rules file
local_rules_file="/usr/local/etc/snort3/rules/local.rules"

# Check if the rules already exist in local.rules
if [ -f "$local_rules_file" ]; then
    while IFS= read -r line; do
        if [[ "$line" == "$snort3_rules" ]]; then
            echo "Rules already exist in local.rules. No changes made."
            rules_exist=true
            break
        fi
    done < "$local_rules_file"
fi

# Append the custom rules to the local.rules file if they don't exist
if [ -z "$rules_exist" ]; then
    echo "$snort3_rules" >> "$local_rules_file"
    echo "Custom rules added to local.rules."
fi


# Append the custom rules to the local.rules file if they don't exist
if [ -z "$rules_exist" ]; then
    echo "$snort3_rules" >> "$local_rules_file"
    echo "Custom rules added to local.rules."
fi


# Set your network interfaces names; set these as they appear in ifconfig
# they will not be renamed during the course of installation
# Check if WAN and LAN are set to specific values
if [ "$WAN" = "hn0" ] && [ "$LAN" = "hn1" ]; then
   echo "WAN and LAN network interfaces are already set to hn0 and hn1."
else
   # Set your network interfaces names
   WAN="hn0"
   LAN="hn1"
   echo "WAN and LAN network interfaces have been set to $WAN and $LAN."
fi

# Check if dnsmasq is already installed
#    pkg info dnsmasq queries the package database to check if dnsmasq is installed.
#    >/dev/null 2>&1 redirects both standard output (stdout) and standard error #  (stderr) to /dev/null to suppress any output or error messages. This makes #  the check silent and only returns an exit status.
if pkg info dnsmasq >/dev/null 2>&1; then
    echo "dnsmasq is already installed."
else
    # Install dnsmasq
    pkg install -y dnsmasq
    echo "dnsmasq has been installed."
fi
# The sysrc utility retrieves rc.conf(5) variables	from the collection of  system rc files and allows  processes  with  appropriate	 privilege  to
# change values in safe and effective manner.
# Check if forwarding is already enabled
# -q makes the grep 'silent' and => a less cluttered output
# see man grep
#maybe not so good for troubleshooting?
if sysrc -n gateway_enable | grep -q "YES" && [ "$(sysctl -n net.inet.ip.forwarding)" -eq 1 ]; then
    echo "Forwarding is already enabled."
else
    # Enable forwarding
    sysrc gateway_enable="YES"
    sysctl net.inet.ip.forwarding=1
    echo "Forwarding has been enabled."
fi

# Define the LAN IP and netmask settings
requested_ip="192.168.33.1"
requested_netmask="255.255.255.0"

# Check if the LAN IP configuration is already set
if ifconfig ${LAN} | grep -q "inet ${requested_ip} netmask ${requested_netmask}"; then
    echo "LAN IP is already set to ${requested_ip}."
else
    # Set LAN IP
    ifconfig ${LAN} inet ${requested_ip} netmask ${requested_netmask}
    
    # Make IP setting persistent
    sysrc "ifconfig_${LAN}=inet ${requested_ip} netmask ${requested_netmask}"
    
    echo "LAN IP has been set to ${requested_ip}."
fi
# activates the network interface specified by ${LAN} (e.g., "hn1"), turning it # on and allowing it to send and receive network traffic.
ifconfig ${LAN} up
#configures the network interface to enter promiscuous mode, which allows the #  network interface to capture all network traffic on the network segment 
#  it's  connected to, not just the traffic intended for its own MAC address.
ifconfig ${LAN} promisc


# Check if dnsmasq is enabled to start on boot
dnsmasq_enabled=$(sysrc -n dnsmasq_enable)
if [ "$dnsmasq_enabled" = "YES" ]; then
    echo "dnsmasq is enabled to start on boot."
else
    sysrc dnsmasq_enable="YES"
    echo "dnsmasq has been enabled to start on boot."
fi

# Specify the paths to the configuration file and the variables
config_file="/usr/local/etc/dnsmasq.conf"
interface_setting="interface=${LAN}"
dhcp_range_setting="dhcp-range=192.168.33.50,192.168.33.150,12h"
router_setting="dhcp-option=option:router,192.168.33.1"

# Check if the settings are already in the configuration file
if grep -q "^${interface_setting}$" "$config_file" && \
   grep -q "^${dhcp_range_setting}$" "$config_file" && \
   grep -q "^${router_setting}$" "$config_file"; then
    echo "Settings are already present in $config_file."
else
    # Append the settings to the configuration file
    echo "$interface_setting" >> "$config_file"
    echo "$dhcp_range_setting" >> "$config_file"
    echo "$router_setting" >> "$config_file"
    echo "Settings have been added to $config_file."
fi

# Configure PF for NAT
echo "
ext_if=\"${WAN}\"
int_if=\"${LAN}\"

icmp_types = \"{ echoreq, unreach }\"
services = \"{ ssh, domain, http, ntp, https }\"
server = \"192.168.33.63\"
ssh_rdr = \"2222\"
table <rfc6890> { 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16          \\
                  172.16.0.0/12 192.0.0.0/24 192.0.0.0/29 192.0.2.0/24 192.88.99.0/24    \\
                  192.168.0.0/16 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24            \\
                  240.0.0.0/4 255.255.255.255/32 }
table <bruteforce> persist


#options                                                                                                                         
set skip on lo0

#normalization
scrub in all fragment reassemble max-mss 1440

#NAT rules
nat on \$ext_if from \$int_if:network to any -> (\$ext_if)

#blocking rules
antispoof quick for \$ext_if
block in quick on egress from <rfc6890>
block return out quick on egress to <rfc6890>
block log all 

# Port Forwarding Rule for SSH from Bastion Host to Ubuntu System
rdr pass on $ext_if proto tcp from any to $ext_if port 2222 -> 192.168.33.1 port 22


# Declare an array of pass rules
pass_rules=(
    "pass in quick on \$int_if inet proto udp from any port = bootpc to 255.255.255.255 port = bootps keep state label \"allow access to DHCP server\""
    "pass in quick on \$int_if inet proto udp from any port = bootpc to \$int_if:network port = bootps keep state label \"allow access to DHCP server\""
    "pass out quick on \$int_if inet proto udp from \$int_if:0 port = bootps to any port = bootpc keep state label \"allow access to DHCP server\""
    "pass in quick on \$ext_if inet proto udp from any port = bootps to \$ext_if:0 port = bootpc keep state label \"allow access to DHCP client\""
    "pass out quick on \$ext_if inet proto udp from \$ext_if:0 port = bootpc to any port = bootps keep state label \"allow access to DHCP client\""
    "pass in on \$ext_if proto tcp to port { ssh } keep state (max-src-conn 15, max-src-conn-rate 3/1, overload <bruteforce> flush global)"
    "pass out on \$ext_if proto { tcp, udp } to port \$services"
    "pass out on \$ext_if inet proto icmp icmp-type \$icmp_types"
    "pass in on \$int_if from \$int_if:network to any"
)

# Specify the configuration file
config_file="/etc/pf.conf"

# Loop through the pass rules
for rule in "${pass_rules[@]}"; do
    # Use grep to search for the rule within the configuration file
    if grep -q -F "$rule" "$config_file"; then
        echo "Pass rule already exists in the configuration: $rule"
    else
        # Append the rule to the configuration file if it doesn't exist
        echo "$rule" >> "$config_file"
        echo "Pass rule has been added to the configuration: $rule"
    fi
done
" >> /etc/pf.conf

# Start dnsmasq
service dnsmasq start

# Enable PF on boot
sysrc pf_enable="YES"
sysrc pflog_enable="YES"

# Start PF
service pf start

# Load PF rules
pfctl -f /etc/pf.conf



#!/bin/bash

# Define the marker or comment to identify the location for the NAT rules
marker="#NAT rules"

# Check if the script is run with superuser privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "Please run this script as root."
   exit 1
fi

# Check if the marker exists in pf.conf
if grep -q "$marker" /etc/pf.conf; then
    # Append the port forwarding rule right under the marker
     Define the SSH port forwarding rule
    ssh_port_forwarding_rule="rdr pass on \$ext_if proto tcp from any to \$ext_if port 22 -> 192.168.33.1 port 22"

    # Add the SSH port forwarding rule to pf.conf
    sed -i '/# Port Forwarding Rule for SSH from Bastion Host to Ubuntu System/r /dev/stdin' "$config_file" <<< "$ssh_port_forwarding_rule" 

    # Reload PF rules
    pfctl -f /etc/pf.conf
    echo "PF rules have been reloaded."

    # Restart SSH service on the destination server
    ssh user@192.168.33.59 "sudo service ssh restart"
    echo "SSH service on the destination server has been restarted."
else
    echo "The marker for the NAT rules section was not found in pf.conf. Please make sure to add it."
fi
 
 
 Define the SSH port forwarding rule
ssh_port_forwarding_rule="rdr pass on \$ext_if proto tcp from any to \$ext_if port 22 -> 192.168.33.1 port 22"

# Add the SSH port forwarding rule to pf.conf
sed -i '/# Port Forwarding Rule for SSH from Bastion Host to Ubuntu System/r /dev/stdin' "$config_file" <<< "$ssh_port_forwarding_rule" 