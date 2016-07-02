FROM gliderlabs/alpine:3.4
MAINTAINER Gregory Daynes <gregdaynes@gmail.com>

# update and install curl
RUN apk update && apk add \
    curl \
    git \
    && rm -rf /var/cache/apk/*

ADD ./install-vim.sh /usr/local/bin/install-vim.sh
RUN chmod a+x /usr/local/bin/install-vim.sh

