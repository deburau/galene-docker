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
      - GALENE_TURN=1.2.3.4:1194
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

## Environment variables

| Environment Variable| Value     | Description
| ---                 | ---       | ---
| GALENE_CPUPROFILE   | file      | Store CPU profile in file               
| GALENE_DATA         | directory | Data directory                          
| GALENE_GROUPS       | directory | Group description directory             
| GALENE_HTTP         | address   | Web server address (default ":8443")    
| GALENE_INSECURE     | 1         | Act as an HTTP server rather than HTTPS 
| GALENE_MDNS         | 1         | Gather mDNS addresses                   
| GALENE_MEMPROFILE   | file      | Store memory profile in file            
| GALENE_MUTEXPROFILE | file      | Store mutex profile in file
| GALENE_RECORDINGS   | directory | Recordings directory
| GALENE_REDIRECT     | host      | Redirect to canonical host
| GALENE_RELAY_ONLY   | 1         | Require use of TURN relays for all media traffic
| GALENE_STATIC       | directory | Web server root directory
| GALENE_TURN         | address   | Built-in TURN server address ("" to disable) (default "auto")


## Complete docker-compose Example

I am using it with my own turn server and traefik as reverse proxy.

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
    networks:
      traefik:
    environment:
      - GALENE_CPUPROFILE=/profiles/cpu.profile
      - GALENE_DATA=/data
      - GALENE_GROUPS=/groups
      - GALENE_HTTP=:80
      - GALENE_INSECURE=1
      - GALENE_MDNS
      - GALENE_MEMPROFILE/profiles/mem.profile
      - GALENE_MUTEXPROFILE/profiles/mutex.profile
      - GALENE_RECORDINGS=/recordings
      - GALENE_REDIRECT
      - GALENE_RELAY_ONLY
      - GALENE_STATIC
      - GALENE_TURN=
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"
      - "traefik.http.routers.galene.rule=Host(`galene.example.com`)"
      - "traefik.http.routers.galene.entrypoints=websecure"
      - "traefik.http.routers.galene.tls=true"
      - "traefik.http.routers.galene.tls.domains[0].main=galene.example.com"
      - "traefik.http.routers.galene.service=galene"
      - "traefik.http.services.galene.loadbalancer.server.port=80"
      - "traefik.http.services.galene.loadbalancer.server.scheme=http"
      - "traefik.http.services.galene.loadbalancer.passhostheader=true"
      
networks:
  traefik:
    external: true
```

More examples and complete docs can be found in the [garage44 wiki](https://github.com/garage44/galene/wiki) an the official [site](https://github.com/garage44/galene/wiki).
