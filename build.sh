#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER

log::m-info "Installing $APP repo ..."
build::apt::add-key 508EA4C8
echo -e "deb http://deb.kamailio.org/kamailio jessie main
deb-src http://deb.kamailio.org/kamailio jessie main" > \
    /etc/apt/sources.list.d/kamailio.list
apt-get -q update


log::m-info "Installing essentials ..."
apt-get install -qq -y \
    ca-certificates \
    curl \
    dnsutils \
    git \
    iproute2 \
    jq \
    libcap2-bin


log::m-info "Installing $APP ..."
apt_kamailio_vsn=$(build::apt::get-version kamailio)

log::m-info "apt versions:  kamailio: $apt_kamailio_vsn"
# log::m-info "apt versions:  kamailio: $apt_kamailio_vsn  kamailio: $apt_kamailio_vsn"
apt-get install -qq -y \
    kamailio=$apt_kamailio_vsn \
    $(for mod in ${KAMAILIO_INSTALL_MODS//,/ }; do
        printf 'kamailio-%s-modules ' "$mod"
      done)


log::m-info "Configuring kamailio ..."
rm -rf /etc/kamailio

mkdir /tmp/configs
pushd $_
    git clone -b $KAZOO_CONFIGS_BRANCH --single-branch --depth 1 \
        https://github.com/2600hz/kazoo-configs .

    find -mindepth 1 -maxdepth 1 -not -name kamailio -exec rm -rf {} \;
    rm -rf kamailio/certs

    pushd kamailio
        log::m-info "Fixing /etc paths: /etc/kazoo/kamailio > /etc/kamailio ..."
        for f in $(grep -rl '/etc/kazoo/kamailio' *)
        do
            sed -i -r 's/\/etc\/kazoo\/kamailio/\/etc\/kamailio/g' $f
            grep '/etc/k' $f
        done

        log::m-info "Fixing /lib paths: /usr/lib/64 + /usr/lib/x86_64-linux-gnu ..."
        sed -i '\|^mpath=|s|"\(.*\)"|"\1:/usr/lib/x86_64-linux-gnu/kamailio/modules/"|' default.cfg
        grep 'mpath' $_

        log::m-info "Fixing tls certificate settings ..."
        sed -i '/^method/s/\b[[:alnum:]]*$/TLSv1/' tls.cfg
        sed -i '\|^certificate|s|\(.*\)=\(.*\)|\1= /volumes/kamailio/tls/tls.crt|' $_
        sed -i '\|^private_key|s|\(.*\)=\(.*\)|\1= /volumes/kamailio/tls/tls.key|' $_
        cat $_

        log::m-info "Adding KAZOO_DB_URL section to local.cfg"
        sed -i '/MY_WEBSOCKET_DOMAIN/a \
\
## Defining KAZOO_DB_URL here so I can run it off of a ramfs \
#!ifndef KAZOO_DB_URL \
#!substdef "!KAZOO_DB_URL!text:///volumes/kamailio/dbtext!g" \
#!endif' local.cfg

        log::m-info "Adding secondary and tertiary amqp url substring sections (commented) to local.cfg"
        sed -i "\|MY_AMQP_URL|a \\
# # #!substdef \"!MY_SECONDARY_AMQP_URL!kazoo://guest:guest@127.0.0.1:5672!g\" \\
# # #!substdef \"!MY_TERTIARY_AMQP_URL!kazoo://guest:guest@127.0.0.1:5672!g\"" local.cfg

        sed -i '/udp4_raw_mtu/s/# \(.*\)\b[[:digit:]]\+$/\11500/' $_

        if grep -q MY_AMQP_URL_SECONDARY default.cfg
        then
            log::m-info "Fixing secondary and tertiary amqp url substring collision bug in default.cfg ..."
            sed -i 's/MY_AMQP_URL_SECONDARY/MY_SECONDARY_AMQP_URL/g' default.cfg
            sed -i 's/MY_AMQP_URL_TERTIARY/MY_TERTIARY_AMQP_URL/g' $_
        fi

        log::m-info "We're in docker so let's set logging to stderr ..."
        sed -i '/log_stderror/s/\b\w*$/yes/' default.cfg

        log::m-info "Setting user and group in config"
        sed -i '/Global Parameters/a \user = "kamailio"' default.cfg
        sed -i '/Global Parameters/a \group = "kamailio"' $_

        log::m-info "Setting DNS settings ..."
        sed -i '/DNS Parameters/a \dns_use_search_list = no' default.cfg
        sed -i '/use_dns_failover/s/\b\w*$/on/' $_
        sed -i '/dns_srv_lb/s/\b\w*$/on/' $_
        sed -i '/dns_try_naptr/s/\b\w*$/on/' $_

        log::m-info "Fixing usage error in presence_notify_sync-role.cfg ..."
        sed -i '/onreply_route\[PRESENCE_NOTIFY_FAULT\]/s/onreply/failure/' presence_notify_sync-role.cfg

        log::m-info "Whitelabeling headers ..."
        sed -i '/server_header/s/".*"/"Server: K"/' default.cfg
        sed -i '/user_agent_header/s/".*"/"User-Agent: K"/' $_

        popd

    mv kamailio /etc/
    popd && rm -rf $OLDPWD


log::m-info "Removing unnecessary packages ..."
apt-get purge -y --auto-remove git


log::m-info "Creating directories ..."
mkdir -p \
    /var/run/$APP \
    /volumes/$APP/{tls,dbtext}


log::m-info "Adding fixattr files ..."
tee /etc/fixattrs.d/20-${APP}-perms <<EOF
/volumes/$APP/dbtext true $USER:$USER 0755 0755
/volumes/$APP/tls true $USER:$USER 0700 0700
/var/run/$APP true $USER:$USER 0755 0755
EOF


log::m-info "Setting Ownership & Permissions ..."
chown -R $USER:$USER ~ /etc/kamailio /volumes/$APP


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
