#!/bin/sh

# Additional Feature:
# - Modify the local SSH server port for management purposes
# - Add snort installation and configuration
# - Add test capabilites via a test script 


# Check if the script is run with superuser privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "Please run this script as root."
   exit 1
fi
# Define the marker or comment to identify the location for the NAT rules  s.t
# the rule goes in the right spot
marker="NAT rules"

# Check if the marker exists in pf.conf
if grep -q "$marker" /etc/pf.conf; then
    # Append the port forwarding rule right under the marker
    sed -i "/$marker/a rdr on \$ext_if proto tcp from any to any port 22 -> 192.168.33.59 port 22" /etc/pf.conf
    echo "Port forwarding rule has been added to pf.conf in the NAT rules section."
else
    echo "The marker for the NAT rules section was not found in pf.conf. Please make sure to add it."
fi



#Modify the local ssh server to move it to a different port for management purposes.
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
#add the firewall rule to let in traffic on 2222
# Define the marker or comment to identify the location for the pass rules
marker="pass rules"

# Check if the marker exists in pf.conf
if grep -q "$marker" /etc/pf.conf; then
    # Append the SSH rule for port 2222 right under the marker
    sed -i "/$marker/a #allow incoming SSH traffic on port 2222" /etc/pf.conf
    sed -i "/$marker/a pass in on \$ext_if proto tcp from any to \$ext_if:0 port 2222" /etc/pf.conf
    echo "SSH rule for port 2222 has been added to pf.conf in the pass rules section."
else
    echo "The marker for the pass rules section was not found in pf.conf. Please make sure to add it."
fi
