# Getting started with VM's
-----

    There were some issues getting started with installing freebsd and an Ubuntu vm on windows.  They can mostly be chalked up to typos, errors, reading and understanding which machine needs to have scripts ran on, and making sure that the user is in the right directory.  One issue that came up in the first and second iterations of installation was using  windows Powershell, instead of Powershell.  Apparently there is a difference.

### Installing UBUNTU

One of the primary reasons of failure to launch the ubuntu server properly was grabbing the first ubuntu.iso that was listed on the linked page.  It was not a server edition.  It was a home edition.  After deleting and re-installing a couple times, i re-read the docs and found out i had the wrong edition. 

Downloading the following:"$ sudo apt install kubuntu-desktop podman docker.io zsh tmux ruby-dev fonts-inconsolata autojump bat emacs build-essential cowsay figlet filters fortunes dos2unix containerd python3-pip cargo cmake" took hours on this windows machine.  
TO-DO: increase the throughput from freebsd to ubuntu vm.



## Screenshots

Inline-style:
![alt text](https://gitlab.cecs.pdx.edu/crouchj/secdevops-crouchj/-/blob/main/hw1/reebsdifconfig.png "FreeBSD ifconfig picture")

Inlin-style:
![alt text](https://gitlab.cecs.pdx.edu/crouchj/secdevops-crouchj/-/blob/main/hw1/ubuntuipas.png  "Ubuntu VM ip a s command picture")

.ssh/config
```
cat config
Host ada
  HostName linux.cs.pdx.edu
Host *
    #don't require calling ssh-add to use the agent
    AddKeysToAgent yes
    #macOS has a UseKeychain option, but not every OS does
    IgnoreUnknown UseKeychain
    UseKeychain yes
    #default to forwarding X11
    ForwardX11Trusted yes
    #set default username -- ***CHANGE THIS TO YOUR USERNAME***
    User crouchj
    #This assumes you followed the instructions above
    IdentityFile ~.ssh/id_ed25519
    #keep connection alive every 30 seconds
    ServerAliveInterval 30
    #don't allow for more than 3 consecutive missed keepalives
    ServerAliveCountMax 3

    Host ubuntu-win
    Hostname 192.168.33.133
    ProxyJump 192.168.1.170

```

## UBUNTU CONFIGURATION

There are two different sections to work through on the Ubuntu configuration, connectivity and System configuration.
____

### Connectivity

Connectivity section insures that both VM's have ip addresses.  As long as all of the previous instructions were successfully understood and implemented, the 'ifconfig' and 'ip a s' commands should yield the desired result.  Each VM has their own ip address.

Connecting via SSH from the host system is still not working.  

Expanding the filesystem is also problematic.  After installing the appropriate tool for lvextend, there was no result from "sudo lvextend --extents +100%FREE /dev/ubuntu-vg/ubuntu-lv --resizefs".   The next step is to run sudo lvscan and use the volume labeled ACTIVE.   There were no results for this command either.  After using 'man lvscan' and seeing if any flags might be useful, -a, -v, but these did not improve my results.  

So progress is pending.



