FROM gliderlabs/alpine:3.4
MAINTAINER Gregory Daynes @gregdaynes

# update and install curl
RUN apk update && apk add \
    curl \
    git \
    && rm -rf /var/cache/apk/*

RUN curl -Lso /usr/local/bin/vim-install https://raw.githubusercontent.com/gregdaynes/microservices.wtf/master/vim-install/vim-install
RUN curl -Lso /usr/local/bin/vim-remove https://raw.githubusercontent.com/gregdaynes/microservices.wtf/master/vim-install/vim-remove
RUN curl -Lso ~/.vimrc https://raw.githubusercontent.com/gregdaynes/microservices.wtf/master/vim-install/vimrc
RUN chmod a+x /usr/local/bin/vim-install
RUN chmod a+x /usr/local/bin/vim-remove

