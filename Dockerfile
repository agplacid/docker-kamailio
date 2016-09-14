FROM centos:6

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="centos" \
        os.version="6"

LABEL   app.name="kamailio" \
        app.version="4.3.4"

ENV     KAMAILIO_VERSION=4.3.4

ENV     HOME=/opt/kamailio
ENV     PATH=$HOME/bin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     KAMAILIO_LOG_LEVEL=info

ENV     KAMAILIO_ENABLE_ROLES=websockets,message

VOLUME  ["/var/lib/kamailio"]

# SIP / SIP-TLS
EXPOSE  5060 5060/udp 5061

# WEBSOCKETS
EXPOSE  5064

# ALG / ALG-TLS
EXPOSE  7000 7000/udp 7001 

# USER    kamailio

WORKDIR /opt/kamailio

CMD     ["/usr/bin/entrypoint"]
