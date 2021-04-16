# Galène videoconferencing server

Galène is a videoconferencing server that is easy to deploy (just copy a few files and run the binary) and that requires moderate server resources. It was originally designed for lectures and conferences (where a single speaker streams audio and video to hundreds or thousands of users), but later evolved to be useful for student practicals (where users are divided into many small groups), and meetings (where a few dozen users interact with each other).

Galène's server side is implemented in Go, and uses the Pion implementation of WebRTC. The server has been tested on Linux/amd64 and Linux/arm64, and should in principle be portable to other systems (including Mac OS X and Windows). The client is implemented in Javascript, and works on recent versions of all major web browsers, both on desktop and mobile.

You can find out more on the [Galène website](https://galene.org/).

Source code for this image is available on [GitHub](https://github.com/deburau/galene).

The image itself resides on [Docker Hub](https://hub.docker.com/r/deburau/galene).

## About this image

This image is based on the [galene44 image](https://github.com/garage44/galene). But this image is self contained (you do need to clone the git repo) and it is small, the size is only 15.6MB.

## How to use this image

```bash
docker run -it -p 8443:8443 deburau/galene:latest -turn ""
```

* Open a compatible browser to the [Galène frontend](http://localhost:8443)

:tada: You're now running Galène locally.

> Please note that you may need a slightly more extended setup when you
> want to have conferences between multiple users.

## Using the built in turn server

If you want to use the built in turn server, you have to run the image in host mode:

```bash
docker run -it --network host deburau/galene:latest -turn $(curl -4 ifconfig.co):1194
```

You can replace $(curl -4 ifconfig.co) with your server's ip address.

## Configure data and groups

To configure groups, passwords, ice servers etc. you can use volume mounts.

```bash
mkdir data groups
docker run -it -p 8443:8443 -v $PWD/data:/data -v $PWD/groups:/groups deburau/galene:latest -turn ""
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
    ports:
      - 1194:1194/tcp
      - 1194:1194/udp
    networks:
      traefik:
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"
      - "traefik.http.routers.galene.rule=Host(`galene.example.com`)"
      - "traefik.http.routers.galene.entrypoints=websecure"
      - "traefik.http.routers.galene.tls=true"
      - "traefik.http.routers.galene.tls.domains[0].main=galene.galene.example.com"
      - "traefik.http.routers.galene.service=galene"
      - "traefik.http.services.galene.loadbalancer.server.port=80"
      - "traefik.http.services.galene.loadbalancer.server.scheme=http"
      - "traefik.http.services.galene.loadbalancer.passhostheader=true"
    command:
      - -http
      - :80
      - -insecure
      - -turn
      - ""

networks:
  traefik:
    external: true
```

More examples and complete docs can be found in the [garage44 wiki](https://github.com/garage44/galene/wiki) an the official [site](https://github.com/garage44/galene/wiki).
