ARG DIR=/go/src/galene

FROM golang:latest AS builder
ARG DIR

RUN git clone https://github.com/jech/galene.git $DIR
WORKDIR $DIR
RUN CGO_ENABLED=0 go build -ldflags='-s -w'
RUN mkdir data groups
RUN ls -al

FROM alpine:latest
ARG DIR

LABEL Description="Docker image for the Galène videoconference server"

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
