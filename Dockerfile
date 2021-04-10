ARG DIR=/go/src/galene
ARG VERSION=0.3.2

FROM golang:latest AS builder
ARG DIR
ARG VERSION

RUN git clone --depth 1 --branch galene-$VERSION https://github.com/jech/galene.git $DIR
WORKDIR $DIR
RUN CGO_ENABLED=0 go build -ldflags='-s -w'
RUN mkdir data groups
RUN ls -al

FROM alpine:latest
ARG DIR
ARG VERSION
ARG DOCKER_REPO=$DOCKER_REPO
ARG SOURCE_COMMIT=$SOURCE_COMMIT

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="$DOCKER_REPO"
LABEL org.label-schema.description="Docker image for the Galène videoconference server"
LABEL org.label-schema.url="http://galena.org/"
LABEL org.label-schema.vcs-url="https://github.com/deburau/galene"
LABEL org.label-schema.vcs-ref="$SOURCE_COMMIT"
LABEL org.label-schema.vendor="jech"
LABEL org.label-schema.version="$VERSION"
LABEL org.label-schema.docker.cmd="docker run -it -p 8443:8443 deburau/galene:latest -turn ''"

EXPOSE 8443
EXPOSE 1194/tcp
EXPOSE 1194/udp

COPY --from=builder $DIR/LICENCE /
COPY --from=builder $DIR/galene /galene
COPY --from=builder $DIR/static/ /static/
COPY --from=builder $DIR/data/ /data/
COPY --from=builder $DIR/groups/ /groups/

VOLUME ["/data", "/groups"]

ENTRYPOINT ["/galene"]
