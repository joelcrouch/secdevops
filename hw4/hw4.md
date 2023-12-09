### INSTALL Wiregaurd
Grab a wireguad docker image:
```sudo docker pull linuxserver/wireguard```, and then make a directory named wiregaurd or something memorable.  I discovered wiregaurd-easy online and used that for a model and ran this docker-compose file:
```
version: '3'
services:
  samba:
    image: dperson/samba
    restart: unless-stopped
    volumes:
      - /shared:/mount
    command: '-s "shared;/mount;yes;no;no;all;all" 
    ports:
      - 139:139
      - 445:445

  pihole:
    image: pihole/pihole:latest
    restart: unless-stopped
    environment:
      TZ: 'America/Los_Angeles'
      WEBPASSWORD: 'user'
    volumes:
      - ./etc-pihole/:/etc/pihole/
      - ./etc-dnsmasq.d/:/etc/dnsmasq.d/
    ports:
      - 5353:5353/tcp
      - 5353:5353/udp
      - 67:67/udp
      - 80:80
      - 443:443

  wg-easy:
    image: weejewel/wg-easy
    container_name: wg-easy
    environment:
      - WG_HOST=172.18.0.1
    volumes:
      - ~/.wg-easy:/etc/wireguard
    ports:
      - '51820:51820/udp'
      - '51821:51821/tcp'
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv4.ip_forward=1
    restart: unless-stopped
    ```

I had to add a bunch of rules to pf.conf:
Some redirect rules in the NAT section:
rdr pass on $ext_if proto udp from any to $ext_if port 51821 -> 192.168.33.1 port 51820
rdr pass on $ext_if proto tcp from any to $ext_if port 51821 -> 192.168.33.1 port 51821

And some more pass in/pass out quick rules for udp and tcp:
pass in quick on $ext_if proto udp from $ext_if port 51820 to 192.168.33.1
pass out quick on $int_if proto udp from 192.168.33.1port 51820 to $ext_if
pass in quick on $ext_if proto tcp from $ext_if port 51821 to 192.168.33.1
pass out quick on $int_if proto tcp from 192.168.33.1 port 51821 to $ext_if

Now i can open up a brownser and goto 172.18.0.1:51821 and connect ot the vpn.

###WAZUH
This took forever.  I cancelled it twice, thinking there was some problem, then just left it overnight.  I guess I should get used to the time allotment, if i am doing this on windows.  Maybe i will try this on my linux machine and compare/contrast time deltas.  Anyways.

The wazuh guide tells you to clone the repo, and run that docker-compose rule:
```git clone https://github.com/wazuh/wazuh-docker.git -b v4.7.0
docker-compose -f generate-indexer-certs.yml run --rm generator
docker-compose up -d```
I ahd to add some more rules to pf.conf to make sure Wazuh works:
rdr pass on $ext_if proto tcp from any to $ext_if port 443 -> 192.168.33.1 port 443
pass in on $ext_if proto tcp from $ext_if port 443 to 192.168.33.19
pass out on $int_if proto tcp from 192.168.33.1 port 443 to $ext_if
```

### WAZUH AGENT Instructions
Run "pkg install wazuh-agent"
Change in "/var/ossec/etc/ossec.conf" the address to the ubuntu server address.    This will allow the server to have an 'instance' (for lack of a more precise term, Maybe presence) in Wazuh.  Then reload the system daemons :
```systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent```, and you are good to go.  Pull itup on a browser with the ubuntu address. 