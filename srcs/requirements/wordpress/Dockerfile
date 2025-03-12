FROM alpine:3.20

ARG MARIADB_NAME MARIADB_USER MARIADB_PWD WP_USER WP_PASS WP_EMAIL

RUN apk update && apk add php php83 php83-fpm php83-mysqli php83-mbstring php83-gd php83-opcache php83-phar php82-xml mariadb-client wget tar

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]