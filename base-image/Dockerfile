FROM gliderlabs/alpine:3.3
MAINTAINER Gregory Daynes <gregdaynes@gmail.com>

# update and install curl
RUN apk update && apk add \
    curl \
    && rm -rf /var/cache/apk/*

COPY install-vim.sh /etc/opt/install-vim.sh
