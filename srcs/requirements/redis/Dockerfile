FROM alpine:3.20

RUN apk update && apk add redis

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6379

CMD [ "redis-server" ]