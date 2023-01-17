<!--
![Docker Pulls](https://img.shields.io/docker/pulls/deburau/galene-docker?style=plastic)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/deburau/galene-docker?style=plastic)
![GitHub](https://img.shields.io/github/license/deburau/galene-docker?style=plastic)
-->
# Galène videoconferencing server

Galène is a videoconferencing server that is easy to deploy (just copy a few files and run the binary) and that requires moderate server resources. It was originally designed for lectures and conferences (where a single speaker streams audio and video to hundreds or thousands of users), but later evolved to be useful for student practicals (where users are divided into many small groups), and meetings (where a few dozen users interact with each other).

Galène's server side is implemented in Go, and uses the Pion implementation of WebRTC. The server has been tested on Linux/amd64 and Linux/arm64, and should in principle be portable to other systems (including Mac OS X and Windows). The client is implemented in Javascript, and works on recent versions of all major web browsers, both on desktop and mobile.

You can find out more on the [Galène website](https://galene.org/).

Source code for this image is available on [GitHub](https://github.com/deburau/galene-docker).

The image itself resides on [Docker Hub](https://hub.docker.com/r/deburau/galene).

## About this image

This image is based on the [galene44 image](https://github.com/garage44/galene). But this image is self contained (you do need to clone the git repo) and it is small, the size is only 15.6MB.

Configuration is possible through environment variables.

## How to use this image

```bash
docker run -it -p 8443:8443 -e GALENE_TURN= deburau/galene:latest
```

Or using docker-compose

```yaml
version: '3'

services:
  galene:
    image: deburau/galene:latest
    container_name: galene
    restart: always
    ports:
      - 8443:8443
    environment:
      - GALENE_TURN=
```

* Open a compatible browser to the [Galène frontend](http://localhost:8443)

:tada: You're now running Galène locally.

> Please note that you may need a slightly more extended setup when you
> want to have conferences between multiple users.

## Using the built in turn server

If you want to use the built in turn server, you have to run the image in host mode:

```bash
docker run -it --network host -e GALENE_TURN=$(curl -4 ifconfig.co):1194 deburau/galene:latest
```

You can replace $(curl -4 ifconfig.co) with your server's ip address.

Docker-compose:

```yaml
version: '3'

services:
  galene:
    image: deburau/galene:latest
    container_name: galene
    restart: always
    network_mode: host
    environment:
      - GALENE_TURN=:1194
```

## Configure data and groups

To configure groups, passwords, ice servers etc. you can use volume mounts.

```bash
mkdir data groups
docker run -it \
  -p 8443:8443 \
  -e GALENE_TURN= \
  -e GALENE_DATA=/data \
  -e GALENE_GROUPS=/groups \
  -v $PWD/data:/data \
  -v $PWD/groups:/groups deburau/galene:latest
```

Docker-compose:

```yaml
version: '3'

services:
  galene:
    image: deburau/galene:latest
    container_name: galene
    restart: always
    volumes:
      - ./data:/data
      - ./groups:/groups
    ports:
      - 8443:8443
    environment:
      - GALENE_DATA=/data
      - GALENE_GROUPS=/groups
      - GALENE_TURN=
```

### Setting the admin password

```bash
echo "admin:topsecret" > data/passwd
```


### Creating a group

```bash
cat > groups/mygroup.json <<EOF
{
    "codecs": ["vp8", "vp9", "opus"],
    "autolock": false,
    "op": [{"username": "myname", "password": "mypassword"}],
    "presenter": [{"password": "grouppassword"}]
}
EOF
```

### Configuring your own turn server

If you are running your own turn server, eg. coTURN, configure it like

```bash
cat > data/ice-servers.json <<EOF
[
    {
        "Urls": [
            "turn:turn.example.com:5349?transport=tcp",
            "turn:turn.example.com:5349?transport=udp"
        ],
        "credential": "my-static-auth-secret",
        "credentialType": "hmac-sha1"
    }
]
EOF
```

To let the container wait the turn server to start, you can use [docker-compose-wait](https://github.com/ufoscout/docker-compose-wait). docker-compose-wait is configured through environment variables, you can read about them on the docker-compose-wait [page](https://github.com/ufoscout/docker-compose-wait).

## Environment variables

| Environment Variable      | Value     | Description
| ---                       | ---       | ---
| GALENE_CPUPROFILE         | file      | Store CPU profile in file               
| GALENE_DATA               | directory | Data directory                          
| GALENE_GROUPS             | directory | Group description directory             
| GALENE_HTTP               | address   | Web server address (default ":8443")    
| GALENE_INSECURE           | 1         | Act as an HTTP server rather than HTTPS 
| GALENE_MDNS               | 1         | Gather mDNS addresses                   
| GALENE_MEMPROFILE         | file      | Store memory profile in file            
| GALENE_MUTEXPROFILE       | file      | Store mutex profile in file
| GALENE_RECORDINGS         | directory | Recordings directory
| GALENE_REDIRECT           | host      | Redirect to canonical host
| GALENE_RELAY_ONLY         | 1         | Require use of TURN relays for all media traffic
| GALENE_STATIC             | directory | Web server root directory
| GALENE_TURN               | address   | Built-in TURN server address ("" to disable) (default "auto")
| WAIT_LOGGER_LEVEL         | loglevel  | The output logger level. Valid values are: debug, info, error, off. the default is debug.
| WAIT_HOSTS                |           | Comma separated list of pairs host:port for which you want to wait.
| WAIT_HOSTS_TIMEOUT        | number    | Max number of seconds to wait for all the hosts to be available before failure. The default is 30 seconds.
| WAIT_HOST_CONNECT_TIMEOUT | number    | The timeout of a single TCP connection to a remote host before attempting a new connection. The default is 5 seconds.
| WAIT_BEFORE_HOSTS         | number    | Number of seconds to wait (sleep) before start checking for the hosts availability
| WAIT_AFTER_HOSTS          | number    | Number of seconds to wait (sleep) once all the hosts are available
| WAIT_SLEEP_INTERVAL       | number    | Number of seconds to sleep between retries. The default is 1 second.


## Complete docker-compose Example

I am using it with the builtin turn server and traefik as reverse proxy.

For this to work, you have to make a change in your trafik configuration, if traefik is running as a docker container. Add the following lines to your docker-compose.yml

```yaml
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

You have to use a newer docker version, I am currently using 20.10.22.

Then create `config.json` in your config directory, e.g. `data/config.json` (replace proxyURL)

```json
{
    "proxyURL": "https://galene.example.com/",
    "admin":[{"username":"admin","password":"secretpassword"}]
}
```

After that, create the `docker-compose.yml` (again, replace the domain name)

```yaml
version: '3'

services:
  galene:
    image: deburau/galene:latest
    container_name: galene
    restart: always
    volumes:
      - ./data:/data
      - ./groups:/groups
      - ./recordings:/recordings
      - ./profiles:/profiles
    network_mode: host
    environment:
      - GALENE_DATA=/data
      - GALENE_GROUPS=/groups
      - GALENE_HTTP=:4080
      - GALENE_INSECURE=1
      - GALENE_RECORDINGS=/recordings
      - GALENE_REDIRECT
      - GALENE_TURN=:1194
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"
      - "traefik.http.routers.galene.rule=Host(`galene.example.com`)"
      - "traefik.http.routers.galene.entrypoints=websecure"
      - "traefik.http.routers.galene.tls=true"
      - "traefik.http.routers.galene.tls.domains[0].main=galene.example.com"
      - "traefik.http.routers.galene.service=galene"
      - "traefik.http.services.galene.loadbalancer.server.port=4080"
      - "traefik.http.services.galene.loadbalancer.server.scheme=http"
      - "traefik.http.services.galene.loadbalancer.passhostheader=true"
```

Be sure to block access to the port 4080 (or any port you choose) from the internet. This port must be reachable from the traefik container. For me, running on Ubuntu, I used the command

```sh
sudo ufw allow proto tcp from 172.16.0.0/12 to any port 4080
```

Also the turn port (1194 for me) should be reachable from the internet

```sh
sudo ufw allow port 1194
```

Eventually all outgoing traffic should be allowed. If not, adjust your firewall accordingly.
