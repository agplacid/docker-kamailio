FROM callforamerica/debian

MAINTAINER joe <joe@valuphone.com>

ARG     KAMAILIO_VERSION
ARG     KAZOO_CONFIGS_BRANCH

ENV     KAMAILIO_VERSION=${KAMAILIO_VERSION:-4.4.3} \
        KAZOO_CONFIGS_BRANCH=${KAZOO_CONFIGS_BRANCH:-master}

LABEL   app.kamailio.version=$KAMAILIO_VERSION

ENV     HOME=/opt/kamailio

COPY    build.sh /tmp/
RUN     /tmp/build.sh

# bug with docker hub automated builds when interating with root directory
# ref: https://forums.docker.com/t/automated-docker-build-fails/22831/27
# COPY    entrypoint /entrypoint
COPY    entrypoint /tmp/
RUN     mv /tmp/entrypoint /

COPY    sync-freeswitch-servers /usr/local/bin/
COPY    protocols /etc/

ENV     KAMAILIO_LOG_LEVEL=info \
        KAMAILIO_ENABLE_ROLES=websockets,message

VOLUME  ["/volumes/ram", "/volumes/tls"]

# SIP-TCP / SIP-UDP / SIP-TLS
EXPOSE  5060 5060/udp 5061

# WS-TCP / WS-UDP / WSS-TCP / WSS-UDP
EXPOSE  5064 5064/udp 5065 5065/udp

# ALG-TCP / ALG-UDP / ALG-TLS
EXPOSE  7000 7000/udp 7001 

# USER    kamailio

WORKDIR /opt/kamailio

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
