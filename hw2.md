## Firewall Rules

In this section, we'll document the firewall rule that forwards SSH traffic from the bastion host to your Ubuntu system.

### Rule to Forward SSH Traffic

We will create a rule in the FreeBSD PF firewall configuration to forward incoming SSH traffic from the bastion host (port 22) to your Ubuntu system's port 22. This will allow you to access your Ubuntu system securely through the bastion host.


# Port Forwarding Rule for SSH from Bastion Host to Ubuntu System
```bash
    rdr pass on hn0 proto tcp from any to hn0 port 22 -> 192.168.33.1 port 22
```
In the rule above: 
    "rdr pass on hn0" instructs PF to perform port forwarding on the WAN interface (hn0)
    "proto top" specifies this rule is for TCP traffic (SSH uses TCP)
    "from any" means the source is any host
    "to hn0 port 22" defines the destination as the WAN interface (hn0) on port 22(bastion hosts ssh port)
    "-> 192.168.33.1 port 22"  specifies the traffic should be forwared to the Ubuntu system (IP: 192.168.33.1) on port 22 (ubuntu ssh port)


## SSH Port Configuration

To enhance security, the SSH server port has been changed for management purposes. Here's how this change was made:

1. A new SSH port, 2222, was chosen for management.

2. The SSH server configuration file was modified to use the new port. The following lines were added to the `/etc/ssh/sshd_config` file:
```bash
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
```

## Snort Installation and Configuration

To enhance network security, Snort, an open-source intrusion detection system (IDS), has been installed and configured on the bastion host. Here's a summary of the installation and configuration steps:

### Installation

```bash
# Install Snort on the bastion host
    if pkg info snort >/dev/null 2>&1; then
        echo "Snort is already installed."
    else
        pkg install -y snort
        echo "Snort has been installed."
    fi
```
In the script above, there is a check to see if snort is installed, and installed if necessary.

### Snort Configuration

# Configure Snort to load at boot time
```bash
snort_enable=$(sysrc -n snort_enable)
if [ "$snort_enable" = "YES" ]; then
    echo "Snort is already set to load at boot time."
else
    sysrc snort_enable="YES"
    echo "Snort has been configured to load at boot time."
fi
```
In the script above, a check to see if snort is enabled at boot is implemented, and if not set to load at boot time, snort is enabled to load at boot time.

# Snort rules and local_rules file

```bash
    snort_rules="
    alert tcp any any -> any 2222 (msg:\"SSH connection attempt\"; sid:100001;)
    alert icmp any any -> any any (msg:\"ICMP traffic detected\"; sid:100002;)"
    # Add more custom rules here

    # Check if local.rules file exists
    if [ -f /usr/local/etc/snort/rules/local.rules ]; then
        echo "local.rules already exists."
    else
        # If it doesn't exist, create the local.rules file
        touch /usr/local/etc/snort/rules/local.rules
        echo "local.rules has been created."
    fi

    # Path to the local.rules file
    local_rules_file="/usr/local/etc/snort/rules/local.rules"

    # Check if the rules already exist in local.rules
    if [ -f "$local_rules_file" ]; then
        while IFS= read -r line; do
            if [[ "$line" == "$snort_rules" ]]; then
                echo "Rules already exist in local.rules. No changes made."
                rules_exist=true
                break
            fi
        done < "$local_rules_file"
    fi

    # Append the custom rules to the local.rules file if they don't exist
    if [ -z "$rules_exist" ]; then
        echo "$snort_rules" >> "$local_rules_file"
        echo "Custom rules added to local.rules."
    fi


    # Append the custom rules to the local.rules file if they don't exist
    if [ -z "$rules_exist" ]; then
        echo "$snort_rules" >> "$local_rules_file"
        echo "Custom rules added to local.rules."
    fi
```

The code above does some stuff. First there is a list of snort rules. More can be added 
as necessary.  This is somewhat clunky, and an external file could be added such that when the two files, freebsdsetufirewall.sh and snort_rules are downloaded, the setup script will reference and update the snort rules, without going in and changing this script. 
Then create the local.rules file, if necessary. After that, the rules are read and if one or more rule(s) need to be added, only that rule will be added.