FROM mswtf/container-pilot:2.3
MAINTAINER Gregory Daynes @gregdaynes

# Install Nginx
RUN apk update && apk add \
    nginx \
    unzip \
    && rm -rf /var/cache/apk/*

# consul-template to re-write Nginx virtualhost config
ENV CONSUL_TEMPLATE_VERSION 0.15.0
RUN curl -Lo /tmp/consul_template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
    unzip /tmp/consul_template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
        mv consul-template /bin

# our nginx commands
COPY nginx.sh /bin

EXPOSE 80
