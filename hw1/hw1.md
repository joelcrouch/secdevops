# Getting started with VM's
-----

    There were some issues getting started with installing freebsd and an Ubuntu vm on windows.  They can mostly be chalked up to typos, errors, reading and understanding which machine needs to have scripts ran on, and making sure that the user is in the right directory.  One issue that came up in the first and second iterations of installation was using  windows Powershell, instead of Powershell.  Apparently there is a difference.

## UBUNTU Configuration 

  During the install of the ubuntu server, there were a few missteps.  The first time the server was successfully installed, after running this command: 'sudo apt install kubuntu-desktop podman docker.io zsh tmux ruby-dev fonts-inconsolata autojump bat emacs build-essential cowsay figlet filters fortunes dos2unix containerd python3-pip cargo cmake', some directions I had found online indicated that I should use 'lightdm' instead of the packaged "sddm".  After installing lightdm, and rebooting the system, the server did have more options to login.  It had vanilla ubuntu, not kubuntu. Once the log in process was complete, there wa sno access to files and no terminal. I reinstalled the server and used vanilla kubuntu, and it worked. 

## Screenshots

Inline-style:
![alt text](https://gitlab.cecs.pdx.edu/crouchj/secdevops-crouchj/-/blob/main/hw1/reebsdifconfig.png "FreeBSD ifconfig picture")

Inlin-style:
![alt text](https://gitlab.cecs.pdx.edu/crouchj/secdevops-crouchj/-/blob/main/hw1/ubuntuipas.png  "Ubuntu VM ip a s command picture")

.ssh/config
```
# Host ada 
#   Hostname linux.cs.pdx.edu 

# Host *
#   #don't require calling ssh-add to use the agent
#   AddKeysToAgent yes
#   #macOS has a UseKeychain option, but not every OS does
#   IgnoreUnknown UseKeychain
#   UseKeychain yes
#   #default to forwarding X11
#   ForwardX11Trusted yes
#   #set default username -- ***CHANGE THIS TO YOUR USERNAME***
#   User your_user_name_here
#   #This assumes you followed the instructions above
#   IdentityFile ~.ssh/id_ed25519
#   #keep connection alive every 30 seconds
#   ServerAliveInterval 30
#   #don't allow for more than 3 consecutive missed keepalives
#   ServerAliveCountMax 3

Host JC-HOST-FREEBSD
  HostName 172.27.133.36 
  User root
  IdentityFile ~/.ssh/free_bsd

Host Pony_1
  HostName 192.168.33.59
  User jelly
  ProxyJump JC-HOST-FREEBSD

Host babbage.cs.pdx.edu
  HostName babbage.cs.pdx.edu
  User crouchj

```

## UBUNTU CONFIGURATION

There are two different sections to work through on the Ubuntu configuration, connectivity and System configuration.
____

### Connectivity

Connectivity section insures that both VM's have ip addresses.  As long as all of the previous instructions were successfully understood and implemented, the 'ifconfig' and 'ip a s' commands should yield the desired result.  Each VM has their own ip address.

Connecting via SSH from the host system is still not working.  

Expanding the filesystem is also problematic.  After installing the appropriate tool for lvextend, there was no result from "sudo lvextend --extents +100%FREE /dev/ubuntu-vg/ubuntu-lv --resizefs".   The next step is to run sudo lvscan and use the volume labeled ACTIVE.   There were no results for this command either.  After using 'man lvscan' and seeing if any flags might be useful, -a, -v, but these did not improve my results.  

So progress is pending.



