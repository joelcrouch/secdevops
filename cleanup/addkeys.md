### ADD keys to FREEBSD
Generate some keys on the admin machine.  Find the public key that was just generated and copy it to the .ssh/authorized_keys file. You may have to create the authorized_keys file.
Then got to sshd_config and authorize the use of ssh keys, by uncommenting this line 
```bash
    PubkeyAuthentication yes
```
and make sure this line is uncommmented and 'yes'

``` bash 
    PermitRootLogin yes
```

uncommenting this line 'should' resolve the password requirement :  
``` bash 
    PasswordAuthentication no
```
and then run in the terminal
 ```bash 
    service sshd restart
```

after that you should be able to ssh into freebsd host.