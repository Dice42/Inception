#!/bin/sh

if [ ! -f /etc/self-signed.crt ]; then
    openssl \
        req -x509 \
        -nodes \
        -subj "/CN=mohammoh.42.fr" \
        -addext "subjectAltName=DNS:mohammoh.42.fr" \
        -days 365 \
        -newkey rsa:2048 -keyout /etc/self-signed.key \
        -out /etc/self-signed.crt
fi

nginx -g 'daemon off;'