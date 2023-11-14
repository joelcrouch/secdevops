### SAMBA INSTRUCTION

Install a containerized samba server on your Ubuntu machine. This should be configured to share a directory on your Ubuntu machine via a mapped volume in your container. This directory should be accessible from your host machine. 
Follow instructions here:https://phoenixnap.com/kb/ubuntu-samba
Dont do the following.  

<!-- . Do the following: 
```bash
    sudo apt update
    sudo apt upgrade
    sudo apt install docker.io
    sudo apt install docker-compose
    sudo systemctl start docker
    sudo systemctl enable docker
```
The code above will update and upgrade the system, install docker.io, if necesary and enable docker.

Then you need a .yml file: docker-compose.yml. It defines the services and maps the specified volume to/into the docker container.  The following should be in it
```yml
version: '3'
services:
  samba:
    image: dperson/samba
    container_name: samba-container
    restart: always
    networks:
      - samba-net
    ports:
      - "139:139"
      - "445:445"
    environment:
      - USER=myuser;mypassword
    volumes:
      - /path/to/shared/directory:/mnt/share
    command: "-w MYGROUP -s 'My Shared Folder:/mnt/share:rw:myuser'"

networks:
  samba-net:

```
dperson/samba is the samba repo.
Change <samba-container> to a name for the container you are comfortable with.
Here:```environment:
      - USER=myuser;mypassword```
  we are going to make a really  slapdash attempt at security.  Probably wouldnt be great for production, but here it is.  We are going to use openssl to encrypt the password:  ``` bash 
  echo "USER=user1;password123" | openssl aes-256-cbc -a -salt -out ~/docksecret.txt.encv ```

Make a directory in HOME: mkdir Shared_Samba (chooose a name you like and configure the yml file with the right path)

Make sure the file above is in a 'docker-compose.yml' file.  
Run it with 'sudo docker-compose up -d".  Make sure you run it with sudo priveliges or youll get a boatload of errors, that look like this:
```bash
  docker-compose up -d
  Traceback (most recent call last):
    File "/usr/lib/python3/dist-packages/urllib3/connectionpool.py", line 700, in urlopen
      httplib_response = self._make_request(
    File "/usr/lib/python3/dist-packages/urllib3/connectionpool.py", line 395, in _make_request
      conn.request(method, url, **httplib_request_kw)
    File "/usr/lib/python3.10/http/client.py", line 1283, in request
      self._send_request(method, url, body, headers, encode_chunked)
    File "/usr/lib/python3.10/http/client.py", line 1329, in _send_request
      self.endheaders(body, encode_chunked=encode_chunked)
    File "/usr/lib/python3.10/http/client.py", line 1278, in endheaders
      self._send_output(message_body, encode_chunked=encode_chunked)
    File "/usr/lib/python3.10/http/client.py", line 1038, in _send_output
      self.send(msg)
    File "/usr/lib/python3.10/http/client.py", line 976, in send
      self.connect()
    File "/usr/lib/python3/dist-packages/docker/transport/unixconn.py", line 30, in connect
      sock.connect(self.unix_socket)
  PermissionError: [Errno 13] Permission denied

  During handling of the above exception, another exception occurred:

  Traceback (most recent call last):
    File "/usr/lib/python3/dist-packages/requests/adapters.py", line 439, in send
      resp = conn.urlopen(
    File "/usr/lib/python3/dist-packages/urllib3/connectionpool.py", line 756, in urlopen
      retries = retries.increment(
    File "/usr/lib/python3/dist-packages/urllib3/util/retry.py", line 532, in increment
      raise six.reraise(type(error), error, _stacktrace)
    File "/usr/lib/python3/dist-packages/six.py", line 718, in reraise
      raise value.with_traceback(tb)
    File "/usr/lib/python3/dist-packages/urllib3/connectionpool.py", line 700, in urlopen
      httplib_response = self._make_request(
    File "/usr/lib/python3/dist-packages/urllib3/connectionpool.py", line 395, in _make_request
      conn.request(method, url, **httplib_request_kw)
    File "/usr/lib/python3.10/http/client.py", line 1283, in request
      self._send_request(method, url, body, headers, encode_chunked)
    File "/usr/lib/python3.10/http/client.py", line 1329, in _send_request
      self.endheaders(body, encode_chunked=encode_chunked)
    File "/usr/lib/python3.10/http/client.py", line 1278, in endheaders
      self._send_output(message_body, encode_chunked=encode_chunked)
    File "/usr/lib/python3.10/http/client.py", line 1038, in _send_output
      self.send(msg)
    File "/usr/lib/python3.10/http/client.py", line 976, in send
      self.connect()
    File "/usr/lib/python3/dist-packages/docker/transport/unixconn.py", line 30, in connect
      sock.connect(self.unix_socket)
  urllib3.exceptions.ProtocolError: ('Connection aborted.', PermissionError(13, 'Permission denied'))

  During handling of the above exception, another exception occurred:
```   
RUN WITH SUDO!

Run 'sudo docker ps' to see the running container.  You should see some output like this: 
jelly@pbj:~$ sudo docker ps
CONTAINER ID   IMAGE  COMMAND                          CREATED                STATUS   PORTS     NAMES
29ca70cc3ef8   dperson/samba   "/sbin/tini -- /usr/…"   About a minute ago   Restarting (1) 6 seconds ago             samba-container

docker ps also gets you the name of the container and its id. Now you can run:
```bash

```

Well, the 'dperson/samba' repo had some unresolvable errors.  It was probably user error. There are a lot of instructions -->

