FROM gliderlabs/alpine:3.4
MAINTAINER Gregory Daynes <gregdaynes@gmail.com>

# update and install curl
RUN apk update && apk add \
    curl \
    git \
    && rm -rf /var/cache/apk/*

ADD ./vim-install /usr/local/bin/vim-install
ADD ./vim-remove /usr/local/bin/vim-remove
RUN chmod a+x /usr/local/bin/vim-install
RUN chmod a+x /usr/local/bin/vim-remove

