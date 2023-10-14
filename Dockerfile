FROM alpine:3.18

RUN apk add ca-certificates

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT /bin/sh

CMD ["-c", "/entrypoint"]

