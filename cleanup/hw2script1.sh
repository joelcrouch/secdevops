#!/bin/bash

# Check if the script is run with superuser privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "Please run this script as root."
   exit 1
fi

# Define the marker or comment to identify the location for the NAT rules
marker="#NAT rules"

# Check if the marker exists in pf.conf
if grep -q "$marker" /etc/pf.conf; then
    # Define the SSH port forwarding rule
    ssh_port_forwarding_rule="rdr pass on \$ext_if proto tcp from any to \$ext_if port 22 -> 192.168.33.1 port 22"

    # Add the SSH port forwarding rule to pf.conf
    sed -i '/# Port Forwarding Rule for SSH from Bastion Host to Ubuntu System/r /dev/stdin' "$config_file" <<< "$ssh_port_forwarding_rule"

    # Reload PF rules
    pfctl -f /etc/pf.conf
    echo "PF rules have been reloaded."

    # Restart SSH service on the destination server
    #ssh user@192.168.33.59 "sudo service ssh restart"
    #echo "SSH service on the destination server has been restarted."
else
    echo "The marker for the NAT rules section was not found in pf.conf. Please make sure to add it."
fi
