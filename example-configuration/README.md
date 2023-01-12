## My docker example configuration for Galène and Coturn

Assumes Traefik is already installed and working. My traefik docker network is named traefik.

You must change the files to fit your enverionment. Specifically look for IP address 1.2.3.4, domain example.com and strings containing the text  secret.

### Coturn

1. Create certificate and point PATH_TO_CERTIFICATES in docker-compose.yml to it. I'm using a wildcard certificate created with acme.sh.
2. Create file dhp.pem with `openssl dhparam -dsaparam -out dhp.pem 4096`
3. Change IP addresses, domains and secrets

### Galène

1. Change IP addresses, domains and secrets


