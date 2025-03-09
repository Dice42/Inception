FROM alpine:3.20

RUN apk update && apk add nginx 

RUN mkdir -p /data/www

COPY tools/index.html /data/www/index.html

COPY tools/nginx.conf /etc/nginx/nginx.conf

COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT [ "/entrypoint.sh" ]