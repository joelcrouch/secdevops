## Firewall Rules

In this section, we'll document the firewall rule that forwards SSH traffic from the bastion host to your Ubuntu system.

### Rule to Forward SSH Traffic

We will create a rule in the FreeBSD PF firewall configuration to forward incoming SSH traffic from the bastion host (port 22) to your Ubuntu system's port 22. This will allow you to access your Ubuntu system securely through the bastion host.
This rule is added in the "NAT rules" section. It is very important that this rule is placed in the appropriate spot, with the correct syntax.

# Port Forwarding Rule for SSH from Bastion Host to Ubuntu System
```bash
    f grep -q 'rdr on hn0 proto tcp from any to any port 22 -> 192.168.33.59 port 22' /etc/pf.conf; then 
   echo "Port forwarding to 22 is enabled."
else
   marker="#NAT rules"
   line_to_add="rdr on hn0 proto tcp from any to any port 22 -> 192.168.33.59 port 22"
   blank_line=""
   # # Use sed to add the line after the marker
   sed -i '' "/$marker/ a \\
   $line_to_add
   $blank_line" /etc/pf.conf
   pfctl -f /etc/pf.conf
   echo "Port forwarding to 22 has been enabled."
fi

```
The code above checks to see if the rule is already in place, and inserts it if necessary.
In the actual rule above: 
    "rdr pass on $ext_if" instructs PF to perform port forwarding on the WAN interface (hn0)
    "proto tcp" specifies this rule is for TCP traffic (SSH uses TCP)
    "from any" means the source is any host
    "to hn0 port 22" defines the destination as the WAN interface (hn0) on port 22(bastion hosts ssh port)
    "-> other_machine port 22"  specifies the traffic should be forwared to the Ubuntu system (IP: 192.168.33.59) on port 22 (ubuntu ssh port).  other_machine is a variable referring to the external IP of the ubuntu server.

Also you have to ssh into the ubuntu server and enter the command: sudo service ssh restart.

## Test Forwarding Rules
From an external machine, attempt to ssh into the freebsd machine. This should forward you directly to the Ubuntu server
```
ssh <Free BSD Server Name>

```
The above command should take you directly to the ubuntu server.  If your ssh keys are set up properly, you should be in the ubuntu server.
## SSH Port Configuration

To enhance security, and also allow the admin to log onto the freebsd server via SSH,the SSH server port has been changed for management purposes. Here's how this change was made:

1. A new SSH port, 2222, was chosen for management.

2. The SSH server configuration file was modified to use the new port. The following lines were added to the `/etc/ssh/sshd_config` file:
```bash
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
##*************restart the ssh service on ubuntu server too!*********************
```
In the code above a port is chosen (2222), and then the check to see if it has been changed. If the SSH port has not been changed, then it changes it:```bash sed -i '' "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config```  Then restart the sshd service.
## ADD Fire Wall rule that allows traffic on management port
The following lines are the code that adds the firewall rule.
```bash 
##add the firewall rule to let in traffic on 2222
# Define the marker or comment to identify the location for the pass rules
if grep -q 'pass in on \$ext_if proto tcp from any to \$ext_if:0 port 2222' /etc/pf.conf; then
    echo "Traffic on 2222 has been allowed."
else
    echo "Need to add a firewall rule"
    marker="#pass rules"
    line_to_add="pass in on \$ext_if proto tcp from any to \$ext_if:0 port 2222"
    blank_line=""
    sed -i '' "/$marker/ a \\
    $line_to_add
    $blank_line" /etc/pf.conf
    pfctl -f /etc/pf.conf
    echo "SSS traffic to FRREE BSD server been put onto port 2222."
fi
```
Likewise, here, check if the firewall rule is already in place. If not then insert it. This is convoluted and there is definitely a more elegant way of inserting the rule, but it works.
Then this command needs to be run, and its done at the end: 
```bash
pfctl -f /etc/pf.conf

```

### Change in .ssh/config on host machine 
Add a line in the FREEBSD HOST section to show which port should be used for ssh'ing into the FreeBSD Machine.  It should look similar to this: 

```bash
Host JC-HOST-FREEBSD
  HostName <IP_Address of JC-HOST-FREEBSD>
  User <user name>
  Port 2222
  IdentityFile ~/.ssh/free_bsd
```
We chose port 2222 for easy remembering.  Choose a port that you like above 1024.

## TEST for the changing port.
The first test we ran is just a simple 'ssh <nameofhost>', and the ssh command successfully received access to the FreeBSD server.  Then the line in .ssh/config 'Port 2222' was commented out and 'ssh -p 2222 JC-HOST-FREEBSD' received accees to the server.

## FireWall rules for SMB Ghost  
```bash 
#add firewall rulse for smb ghost  
# Insert the custom pass rule before the # Blocking rules section
marker="# Blocking rules"
new_rule="pass in on \$ext_if proto tcp from 192.168.0.1 to \$ext_if port 445"

# Use sed to insert the new rule before the marker
sed -i "/$marker/i $new_rule" /etc/pf.conf

# Insert the custom smbg ghostblock rule after the # blocking rule section
marker="# blocking rule"
new_rule="block in on \$ext_if proto tcp to \$ext_if port 445"

# Use sed to insert the new rule after the marker
sed -i "/$marker/a $new_rule" /etc/pf.conf

```
The commands above should put the firewall rules in the right place for readability and not generating errors. The first allows traffic on port 445 from the admin machine, and the second blocks all the rest of traffic on 445.
## Snort Installation and Configuration

To enhance network security, Snort, an open-source intrusion detection system (IDS), has been installed and configured on the bastion host. Here's a summary of the installation and configuration steps:

### Installation
First i removed snort if it was installed and then reinstalled it.
```bash
if pkg info snort > /dev/null 2>&1; then
    pkg remove -y snort
    rm -rf /usr/local/etc/snort
    echo "Removed existing Snort installation."
fi
```



### Snort Configuration
# Install from source 
Do this if pkg install snort3 does not work properly.  See: https://www.zenarmor.com/docs/linux-tutorials/how-to-install-and-configure-snort-on-freebsd for more details.
Run this code: 
```bash 

```
Well snort3 install didnt work. So installed snort2.9 and followed the istrcutions on snort.com.
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
# enable Snort
After the downlaod, navigate to /etc/rc.conf and add these two lines: 
```bash 
snort_enable="YES"
snort_config="/usr/local/etc/snort/snort.conf"
```
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
Finally I found the SMBG ghost rules at claroty.com, and installed them to the local rules.


The code above does some stuff. First there is a list of snort rules. More can be added 
as necessary.  This is somewhat clunky, and an external file could be added such that when the two files, freebsdsetufirewall.sh and snort_rules are downloaded, the setup script will reference and update the snort rules, without going in and changing this script. 
Then create the local.rules file, if necessary. After that, the rules are read and if one or more rule(s) need to be added, only that rule will be added.