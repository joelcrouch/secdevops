### gitlab stuff
We have to do a few tings to get the gitlac docker running. We need to set environmental variables for data, logs, config and store them /srb/gitlab, such that data is stored at /srv/gitlab/data, etc.  Repeat for logs and config.
Now the docker file has this in it: 
```yml
version: '3.4'
services:
  web:
      image: 'gitlab/gitlab-ee:latest'
      restart: always
      hostname: 'gitlab.example.com'
      environment:
        GITLAB_OMNIBUS_CONFIG: |
          external_url 'https://gitlab.example.com:8929'
          gitlab_rails['gitlab_shell_ssh_port'] = 2224
      ports:
        - '8929:8929'
        - '2224:22'
      volumes:
        - 'srv/gitlab/config:/etc/gitlab'
        - 'srv/gitlab/Logs:/var/log/gitlab'
        - 'srv/gitlab/data:/var/opt/gitlab'
      shm_size: '256m'
```

Those are all essentially defaults from the instructions.  Gitlab docs stipulate the ports, i think. Its been a minute since I did this.


### Bitwarden setup.
So first run 
```mkdir bitwarden  && chmod 777 bitwarden```, to make a diriectory and excutable, etc.
Grab the most recent copy of bitwarden: 
```docker pull bitwardenrs/server:latest```

Per the bitwarden instructions we have to add some data to our docker-compose.yml file, towit: services:
```yml
  bitwarden:
    image: bitwardenrs/server:latest
    container_name: bitwarden
    environment:
      ROCKET_TLS: cert
      SIGNUPS_ALLOWED: 'false'
    volumes:
      - ./bitwarden:/data
    ports:
      - '80:80'
      - '3012:3012'
```
I suppose that in the future, the volume and container name shouldnt be the same.(FUTURE FIX)

### ZONE MINder
ZoneMinder is an integrated set of applications which provide a complete surveillance solution allowing capture, analysis, recording and monitoring of any CCTV or security cameras attached to a Linux based machine.(from the readme or documentation at github.com/Zoneminder)  Follow the instructions.  DONT try to install it from source.  I followed some yahoo's instructions on how to do it form source, and bricked the machine.  So READ the instructions here: https://github.com/ZoneMinder/zoneminder and here (for ubuntu):https://launchpad.net/~iconnor.

The following are additons  to the yaml file: 
```yml
zoneminder:
    image: dlandon/zoneminder:latest
    container_name: zoneminder
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - /home/joel/zm_data:/var/cache/zoneminder
    ports:
      - '8080:80'
      - '9000:9000'
```
### JEKYLL CI/CD
I have tried and tried to get this to work.  
First i thought i coudl just use a docker-compose yml file(agian)and run the jekyll service through that. After reading the docs at Jekylly and finding a few promising github repos, i made a volume that would serve the jekyll instance on port 4000, but that was non-starter.  I coouldn't get that to work.  

Then i thought, well what if i backed it up a bit, and just dockerize it.  I kinda copied the docker-compose.yml file that was relevant to jekyll and stuck it into a Dockerfile.  That didn't work either.  I think maybe I need some other dependency.  
In any case, once i get it up and running it will have to have some type of index.html with some @app routes to handle new files being saved.

So that doesn't work.  
