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
# Install from source 
Do this if pkg install snort3 does not work properly.  See: https://www.zenarmor.com/docs/linux-tutorials/how-to-install-and-configure-snort-on-freebsd for more details.
Run this code: 
```bash 
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
#optional dependencies
pkg install hyperscan cpputest flatbuffers libiconv lzlib e2fsprogs-libuuid google-perftools

cd ~/snort_src
git clone https://github.com/snort3/snort3.git
cd snort3

./configure_cmake.sh --prefix=/usr/local/snort --enable-tcmalloc

cd build/
make
make install
#This takes a while ~30 minutes.

#verify installation
ldd /usr/local/snort/bin/snort

#You should see output like this
# /usr/local/snort/bin/snort:
# libdaq.so.3 => /usr/local/lib/libdaq.so.3 (0x8007c3000)
# libdnet.so.1 => /usr/local/lib/libdnet.so.1 (0x8009c9000)
# libthr.so.3 => /lib/libthr.so.3 (0x8009dd000)
# libhwloc.so.5 => /usr/local/lib/libhwloc.so.5 (0x800a0a000)
# libluajit-5.1.so.2 => /usr/local/lib/libluajit-5.1.so.2 (0x800a3e000)
# libcrypto.so.11 => /usr/local/lib/libcrypto.so.11 (0x800ac6000)
# libpcap.so.1 => /usr/local/lib/libpcap.so.1 (0x800dbc000)
# libpcre.so.1 => /usr/local/lib/libpcre.so.1 (0x800e17000)
# libz.so.6 => /lib/libz.so.6 (0x800ebb000)
# libhs.so.5 => /usr/local/lib/libhs.so.5 (0x800ed7000)
# libiconv.so.2 => /usr/local/lib/libiconv.so.2 (0x801338000)
# libunwind.so.8 => /usr/local/lib/libunwind.so.8 (0x801437000)
# liblzma.so.5 => /usr/lib/liblzma.so.5 (0x801451000)
# libuuid.so.1 => /usr/local/lib/libuuid.so.1 (0x80147d000)
# libtcmalloc.so.4 => /usr/local/lib/libtcmalloc.so.4 (0x801484000)
# libc++.so.1 => /usr/lib/libc++.so.1 (0x80167a000)
# libcxxrt.so.1 => /lib/libcxxrt.so.1 (0x80174c000)
# libm.so.5 => /lib/libm.so.5 (0x80176f000)
# libgcc_s.so.1 => /lib/libgcc_s.so.1 (0x8017a2000)
# libc.so.7 => /lib/libc.so.7 (0x8017bb000)
# libdl.so.1 => /usr/lib/libdl.so.1 (0x801bcc000)
# libpciaccess.so.0 => /usr/local/lib/libpciaccess.so.0 (0x801bd0000)
# libxml2.so.2 => /usr/local/lib/libxml2.so.2 (0x801bda000)
# libibverbs.so.1 => /lib/libibverbs.so.1 (0x801d75000)
# libmd.so.6 => /lib/libmd.so.6 (0x801d87000)
# libexecinfo.so.1 => /usr/lib/libexecinfo.so.1 (0x801da5000)
# libelf.so.2 => /lib/libelf.so.2 (0x801dab000)

#check that it runs
/usr/local/snort/bin/snort -V

# You should see output like this:
# ,,_ -*> Snort++ <*-
# o" )~ Version 3.1.39.0
# '''' By Martin Roesch & The Snort Team
# http://snort.org/contact#team
# Copyright (C) 2014-2022 Cisco and/or its affiliates. All rights reserved.
# Copyright (C) 1998-2013 Sourcefire, Inc., et al.
# Using DAQ version 3.0.9
# Using LuaJIT version 2.0.5
# Using OpenSSL 1.1.1q 5 Jul 2022
# Using libpcap version 1.10.1
# Using PCRE version 8.45 2021-06-15
# Using ZLIB version 1.2.11
# Using Hyperscan version 5.4.0 2022-08-12
# Using LZMA version 5.2.5

#test against default config file
/usr/local/snort/bin/snort -c /usr/local/snort/etc/snort/snort.lua --daq-dir /usr/local/lib/daq

#see output like this:
# Snort successfully validated the configuration (with 0 warnings).
# o")~ Snort exiting
```
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

The code above does some stuff. First there is a list of snort rules. More can be added 
as necessary.  This is somewhat clunky, and an external file could be added such that when the two files, freebsdsetufirewall.sh and snort_rules are downloaded, the setup script will reference and update the snort rules, without going in and changing this script. 
Then create the local.rules file, if necessary. After that, the rules are read and if one or more rule(s) need to be added, only that rule will be added.