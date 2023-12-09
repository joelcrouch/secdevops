#!/bin/sh
#Port 22 forwarding
# Define the line you want to add after the marker
if grep -q 'rdr on hn0 proto tcp from any to any port 22 -> 192.168.33.59 port 22' /etc/pf.conf; then 
   echo "Port forwarding to 22 is enabled."
else
   marker="#NAT rules"
   line_to_add="rdr on hn0 proto tcp from any to any port 22 -> 192.168.33.59 port 22"
   outgoing_line="pass out on hn0 proto tcp from 192.168.33.59 to any port 22"
   blank_line=""
   # # Use sed to add the line after the marker
   sed -i '' "/$marker/ a \\
   $line_to_add
   $blank_line
   $outgoing_line
   $blank_line" /etc/pf.conf
   pfctl -f /etc/pf.conf
   echo "Port forwarding to 22 has been enabled."
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
##*************restart the ssh service on ubuntu server too!*********************

#add the firewall rule to let in traffic on 2222
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

#Snort installation
#Make sure you checkpoint your machines before you start runnign the snort3 installation. this will install snort2, and config files will be usr/local/etc/snort.  Enable at boot will be in usr/locat/etc/rc.d/snort
pkg install snort

#Configuring Snort2

#enable at root delta in rc.d/snort


#get community rules


#config for smbg ghost






## ths was an attmept to install snort3 
#there were some errors in multiple spots. @17%,87% and 13%  Mostly errors related to c++ commands
freebsd-update fetch
freebsd-update install
pkg update
reboot

mkdir ~/snort_src && cd ~/snort_src
pkg install git flex bison gcc cmake
```
# Installing Snort 3 Required Dependencies
pkg install libdnet libpcap hwloc pcre openssl luajit lua51 pkgconf libpcap

#if the wget doesnt work, download it and move over the libdaq-3.0.9 libraray via ssh or winscp or something.  Dont forget to change the port to 2222 because winscp works over the ssh port.
# i have commented it out, b.c the wget didnt work
wget https://github.com/snort3/libdaq/archive/refs/tags/v3.0.9.tar.gz
tar xf v3.0.9.tar.gz  
cd ..
cd libdaq-3.0.9
pkg install autoconf automake libtool
#you might have to chmod +x bootstrap
./bootstrap
./configure
make
make install

#Installing Snort 3 Optional Dependencies
pkg install hyperscan cpputest flatbuffers libiconv lzlib e2fsprogs-libuuid google-perftools

#skip the safec it might fail

cd ~/snort_src
git clone https://github.com/snort3/snort3.git
cd snort3

#compile snort3
./configure_cmake.sh --prefix=/usr/local/snort --enable-tcmalloc

#build it-takes a while~30 minutes
cd build/
make
make install

