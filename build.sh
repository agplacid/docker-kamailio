#!/bin/bash

set -e

app=kamailio
user=$app


# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $app ..."
useradd --home-dir ~ --create-home --shell=/bin/bash --user-group $user


echo "Installing dependencies ..."
apt-get update
apt-get install -y curl ca-certificates git dnsutils jq libcap2-bin


echo "Installing $app repo ..."
curl http://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -
echo -e "deb http://deb.kamailio.org/kamailio jessie main\ndeb-src http://deb.kamailio.org/kamailio jessie main" > /etc/apt/sources.list.d/kamailio.list
apt-get update


echo "Calculating versions for $app ..."
apt_kamailio_version=$(apt-cache show $app | grep ^Version | grep $KAMAILIO_VERSION | sort -n | head -1 | awk '{print $2}')
echo "$app: $apt_kamailio_version"


apt-get install -y \
    kamailio=$apt_kamailio_version \
    kamailio-extra-modules \
    kamailio-ims-modules \
    kamailio-kazoo-modules \
    kamailio-outbound-modules \
    kamailio-presence-modules \
    kamailio-tls-modules \
    kamailio-websocket-modules


echo "Configuring kamailio ..."
rm -rf /etc/kamailio

mkdir /tmp/configs
pushd $_
    git clone -b $KAZOO_CONFIGS_BRANCH --single-branch --depth 1 \
        https://github.com/2600hz/kazoo-configs .

    find -mindepth 1 -maxdepth 1 -not -name kamailio -exec rm -rf {} \;
#!substdef "!KAZOO_DB_URL!text:///etc/kazoo/kamailio/dbtext!g"
    echo "Fixing /etc paths: /etc/kazoo/kamailio > /etc/kamailio ..."
    for f in $(grep -rl '/etc/kazoo/kamailio' *)
    do
        sed -i -r 's/\/etc\/kazoo\/kamailio/\/etc\/kamailio/g' $f
        grep '/etc/k' $f
    done

    echo "Fixing /lib paths: /usr/lib/64 + /usr/lib/x86_64-linux-gnu ..."
    sed -i '\|^mpath=|s|"\(.*\)"|"\1:/usr/lib/x86_64-linux-gnu/kamailio/modules/"|' kamailio/default.cfg
    grep 'mpath' $_

    echo "Fixing tls certificate settings ..."
    sed -i '/^method/s/\b[[:alnum:]]*$/TLSv1/' kamailio/tls.cfg
    sed -i '\|^certificate|s|\(.*\)=\(.*\)|\1= /volumes/tls/tls.crt|' $_
    sed -i '\|^private_key|s|\(.*\)=\(.*\)|\1= /volumes/tls/tls.key|' $_
    cat $_

    rm -rf kamailio/certs
    echo "Adding KAZOO_DB_URL section to local.cfg"
    sed -i '/MY_WEBSOCKET_DOMAIN/a \
\
## Defining KAZOO_DB_URL here so I can run it off of a ramfs \
#!ifndef KAZOO_DB_URL \
#!substdef "!KAZOO_DB_URL!text:///volumes/ram/dbtext!g" \
#!endif' kamailio/local.cfg

    if grep -q MY_AMQP_URL_SECONDARY kamailio/default.cfg
    then
        echo "Fixing secondary and tertiary amqp url substring collision bug in default.cfg ..."
        sed -i 's/MY_AMQP_URL_SECONDARY/MY_SECONDARY_AMQP_URL/g' kamailio/default.cfg
        sed -i 's/MY_AMQP_URL_TERTIARY/MY_TERTIARY_AMQP_URL/g' kamailio/default.cfg
    fi

    echo "Adding secondary and tertiary amqp url substring sections (commented) to local.cfg"
    sed -i "\|MY_AMQP_URL|a \\
# # #!substdef \"!MY_SECONDARY_AMQP_URL!kazoo://guest:guest@127.0.0.1:5672!g\" \\
# # #!substdef \"!MY_TERTIARY_AMQP_URL!kazoo://guest:guest@127.0.0.1:5672!g\"" kamailio/local.cfg
    
    echo "We're in docker so let's set logging to stderr ..."
    sed -i '/log_stderror/s/\b\w*$/yes/' kamailio/default.cfg

    echo "Setting user and group in config"
    sed -i '/Global Parameters/a \user = "kamailio"' kamailio/default.cfg
    sed -i '/Global Parameters/a \group = "kamailio"' kamailio/default.cfg
    
    sed -i '/DNS Parameters/a \dns_use_search_list = no' kamailio/default.cfg
    sed -i '/use_dns_failover/s/\b\w*$/on/' kamailio/default.cfg
    sed -i '/dns_srv_lb/s/\b\w*$/on/' kamailio/default.cfg
    sed -i '/dns_try_naptr/s/\b\w*$/on/' kamailio/default.cfg

    echo "Fixing usage error in presence_notify_sync-role.cfg ..."
    sed -i '/onreply_route\[PRESENCE_NOTIFY_FAULT\]/s/onreply/failure/' kamailio/presence_notify_sync-role.cfg

    echo "Whitelabeling headers ..."
    sed -i '/server_header/s/".*"/"Server: K"/' kamailio/default.cfg
    sed -i '/user_agent_header/s/".*"/"User-Agent: K"/' kamailio/default.cfg
    mv kamailio /etc/
    popd && rm -rf $OLDPWD


echo "Creating tls path ..."
mkdir -p /volumes/tls


echo "Removing unnecessary packages ..."
apt-get purge -y --auto-remove git


echo "Setting Ownership & Permissions ..."
chown -R $user:$user ~ /etc/kamailio


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
