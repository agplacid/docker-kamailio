FROM centos:6

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="centos" \
        os.version="6"

LABEL   app.name="kamailio" \
        app.version="1"

ENV     TERM=xterm \
        HOME= \
        PATH=$HOME:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     KUBERNETES_HOSTNAME_FIX=true \
        HOME=/var/lib/kamailio \
        PATH=$HOME:$HOME/bin:$PATH

VOLUME  ["/var/lib/kamailio"]

# SIP / SIP-TLS
EXPOSE  5060 5060/udp 5061

# ALG / ALG-TLS
EXPOSE  7000 7000/udp 7001 

# USER    kamailio

WORKDIR /var/lib/kamailio

CMD     ["/usr/bin/entrypoint"]
