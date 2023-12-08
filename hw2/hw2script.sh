#!/bin/sh

# Additional Feature:
# - Modify the local SSH server port for management purposes
# - Add snort installation and configuration
# - Add test capabilites via a test script 

#make sure we are referencign the right stuff
WAN="hn0"
LAN="hn1"

# Check if the script is run with superuser privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "Please run this script as root."
   exit 1
fi
#installation of dnsmasq, set up system configurations to enable the system as a gateway, and immediately enable IP forwarding in the networking stack,and make dnamasq enabled on boot
pkg install -y dnsmasq
sysrc gateway_enable="YES"
sysctl net.inet.ip.forwarding=1
sysrc dnsmasq_enable="YES"

#make the IP address setting persistent across system reboots
ifconfig ${LAN} inet 192.168.33.1 netmask 255.255.255.0; sysrc "ifconfig_${LAN}=inet 192.168.33.1 netmask 255.255.255.0"

# Bring the network interface up and set it to promiscuous mode
ifconfig ${LAN} up promisc

# Add or modify settings in sshd_config if they don't exist
{ 
    grep -q "Port 2222" /etc/ssh/sshd_config || echo "Port 2222" >> /etc/ssh/sshd_config
    grep -q "AllowAgentForwarding yes" /etc/ssh/sshd_config || echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config
    sed -i '' -e '/^#*AllowTcpForwarding/s/^#*//' /etc/ssh/sshd_config
    grep -q "GatewayPorts yes" /etc/ssh/sshd_config || echo "GatewayPorts yes" >> /etc/ssh/sshd_config
    grep -q "PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    service sshd restart
}

# Edit dnsmasq configuration
{
  grep -q "interface=${LAN}" /usr/local/etc/dnsmasq.conf || echo "interface=${LAN}" >> /usr/local/etc/dnsmasq.conf
  grep -q "dhcp-range=192.168.33.25,192.168.33.250,12h" /usr/local/etc/dnsmasq.conf || echo "dhcp-range=192.168.33.25,192.168.33.250,12h" >> /usr/local/etc/dnsmasq.conf
  grep -q "dhcp-option=option:router,192.168.33.1" /usr/local/etc/dnsmasq.conf || echo "dhcp-option=option:router,192.168.33.1" >> /usr/local/etc/dnsmasq.conf
} && \
# Set Interface Variables in pf.conf if not already set
{
  grep -q "ext_if=\"${WAN}\"" /etc/pf.conf || echo "ext_if=\"${WAN}\"" >> /etc/pf.conf
  grep -q "int_if=\"${LAN}\"" /etc/pf.conf || echo "int_if=\"${LAN}\"" >> /etc/pf.conf
}
#resend this whole seciton
echo "
ext_if=\"hn0\"
int_if=\"hn1\"

icmp_types = \"{ echoreq, unreach }\"
services = \"{ ssh, domain, http, ntp, https }\"
server = \"192.168.33.59\"
ssh_rdr = \"22\"
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
#re-directing rules
rdr pass on \$ext_if proto tcp from any to \$ext_if port 22 -> hn1 port 22
#blocking rules
antispoof quick for \$ext_if
block in quick on egress from <rfc6890>
block return out quick on egress to <rfc6890>
block log all

pass out on $int_if proto tcp from 172.23.191.155
 to 192.168.33.59 port 22
pass out on $int_if proto tcp from 192.168.33.59 to 192.168.33.1
pass in on $int_if proto udp from 192.168.33.59 to 192.168.33.1
pass in on $int_if proto tcp from 192.168.33.59 to any
pass out on $int_if proto tcp from 192.168.33.59 to any
pass in quick on hn0 proto tcp from 172.23.191.155  to 172.18.0.1
 port 2222
pass in quick on hn0 proto tcp from any to hn0 port 2222
pass in on hn0 proto tcp from any to any port 445

pass on hn0 proto tcp from any to hn0 port 445 divert-to 127.0.0.1 port 31234

#pass rules
pass in quick on \$int_if inet proto udp from any port = bootpc to 255.255.255.255 port = bootps keep state label \"allow access to DHCP server\"
pass in quick on \$int_if inet proto udp from any port = bootpc to \$int_if:network port = bootps keep state label \"allow access to DHCP server\"
pass out quick on \$int_if inet proto udp from \$int_if:0 port = bootps to any port = bootpc keep state label \"allow access to DHCP server\"

pass in quick on \$ext_if inet proto udp from any port = bootps to \$ext_if:0 port = bootpc keep state label \"allow access to DHCP client\"
pass out quick on \$ext_if inet proto udp from \$ext_if:0 port = bootpc to any port = bootps keep state label \"allow access to DHCP client\"

pass in on \$ext_if proto tcp to port { ssh } keep state (max-src-conn 15, max-src-conn-rate 3/1, overload <bruteforce> flush global)
pass out on \$ext_if proto { tcp, udp } to port \$services
pass out on \$ext_if inet proto icmp icmp-type \$icmp_types
" >> "$pf_conf"

service dnsmasq start
sysrc pf_enable="YES"
sysrc pflog_enable="YES"
service pf start
pfctl -f /etc/pf.con


# # Define the marker or comment to identify the location for the NAT rules  s.t
# # the rule goes in the right spot
# if grep -q 'rdr on hn0 proto tcp from any to any port 22 -> 192.168.33.59 port 22' /etc/pf.conf; then
#     echo "Port forwarding to Port 22 from port 22 is already enabled."
# else
#     marker="#NAT rules"
#     line_to_add="rdr on hn0 proto tcp from any to any port 22 -> 192.168.33.59 port 22"
#     blank_line=""
    
#     # Use sed to add the line after the marker
#     sed -i '' "/$marker/ a \\
# $line_to_add
# $blank_line" /etc/pf.conf
#     echo "Port forwarding to Port 22 from port 22 has been enabled."
# fi

# pfctl -f /etc/pf.conf




# #Modify the local ssh server to move it to a different port for management purposes.
# # Choose a new SSH port for management purposes
# new_ssh_port="2222"

# # Modify SSH server configuration to use the new port
# if grep -q "^Port $new_ssh_port$" "/etc/ssh/sshd_config"; then
#     echo "SSH port is already set to $new_ssh_port."
# else
#     # Edit the SSH configuration to change the port
#     sed -i '' "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config

#     # Restart the SSH service to apply changes
#     service sshd restart

#     echo "SSH port has been set to $new_ssh_port."
# fi
# #add the firewall rule to let in traffic on 2222
# # Define the marker or comment to identify the location for the pass rules
# if grep -q 'pass in on \$ext_if proto tcp from any to \$ext_if:0 port 2222' /etc/pf.conf; then
#     echo "Traffic on 2222 has been allowed."


# # marker="pass rules"

# # Check if the marker exists in pf.conf
# if grep -q "$marker" /etc/pf.conf; then
#     # Append the SSH rule for port 2222 right under the marker
#     sed -i "/$marker/a #allow incoming SSH traffic on port 2222" /etc/pf.conf
#     sed -i "/$marker/a pass in on \$ext_if proto tcp from any to \$ext_if:0 port 2222" /etc/pf.conf
#     echo "SSH rule for port 2222 has been added to pf.conf in the pass rules section."
# else
#     echo "The marker for the pass rules section was not found in pf.conf. Please make sure to add it."
# fi

#ADD snort stuff, install, runt at boot get home_net variable rght
#followed the guidleines here:https://www.snort.org/snort2
# Uninstall Snort if it's already installed
if pkg info snort > /dev/null 2>&1; then
    pkg remove -y snort
    rm -rf /usr/local/etc/snort
    echo "Removed existing Snort installation."
fi
#first install snort and make it run at boot
pkg install -y snort && sysrc snort_enable="YES"
#download and unzip  the snort 2.9 rules(coulndt get 3 going)
pkg install -y curl
pkg install -y libarchive
#for some reason i did not have tar installed or it wasnt working
curl -L https://www.snort.org/downloads/community/community-rules.tar.gz | tar -xzvf - -C /usr/local/etc/snort/rules --strip-components=1
#pipe the curl to the tar
#first get hte right home-net in snort.ocnf
sed -i '' -E "s/ipvar HOME_NET \[YOU_NEED_TO_SET_HOME_NET_IN_snort.conf\]/ipvar HOME_NET \$(ifconfig hn0 | awk '/inet / {print \$2}')/" /usr/local/etc/snort/snort.conf

#the following were acquired from running the instruction from snort throug chatgpt
sed -i '' -E 's/^config logdir:.*/config logdir: \/var\/log\/snort/' /usr/local/etc/snort/snort.conf \
    -e 's/var WHITE_LIST_PATH ..\/rules/var WHITE_LIST_PATH rules/' \
    -e 's/var BLACK_LIST_PATH ..\/rules/var BLACK_LIST_PATH rules/' \
    -e 's/var RULE_PATH .\/rules/var RULE_PATH rules/' /usr/local/etc/snort/snort.conf

#now make the empty files for the bladck and white list
touch /usr/local/etc/snort/rules/white_list.rules
touch /usr/local/etc/snort/rules/black_list.rules
 
#now remove the $RULEPATH since you will be using the community rules
sed -i '' '/include $RULE_PATH/d' /usr/local/etc/snort/snort.conf
if ! grep -q "include \$RULE_PATH/community.rules" /usr/local/etc/snort/snort.conf; then
    echo "include \$RULE_PATH/community.rules" >> /usr/local/etc/snort/snort.conf
fi
# thise arre some smbg ghost rules i didnt make thme after mcuh googlign foudn them at cloroty
echo "
block tcp any any -> any 445 (msg:\"Claroty Signature: SMBv3 Used with compression - Client to server\"; content:\"|fc 53 4d 42|\"; offset: 0; depth: 10; sid:1000001; rev:1; reference:url,//blog.claroty.com/advisory-new-wormable-vulnerability-in-microsoft-smbv3;)
block tcp any 445 -> any any (msg:\"Claroty Signature: SMBv3 Used with compression - Server to client\"; content:\"|fc 53 4d 42|\"; offset: 0; depth: 10; sid:1000002; rev:1; reference:url,//blog.claroty.com/advisory-new-wormable-vulnerability-in-microsoft-smbv3;)
" > ./rules/local.rules

service snort restart
