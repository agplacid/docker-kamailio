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
apt-get install -y curl ca-certificates git dnsutils jq


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
rm -rf /etc/kamailio/*

cd /tmp
	git clone -b master --single-branch --depth 1 \
		https://github.com/2600hz/kazoo-configs kazoo-configs
	pushd $_
		find -mindepth 1 -maxdepth 1 -not -name kamailio -exec rm -rf {} \;

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

        echo "Moving dbtext to /volumes/ram/dbtext ..."
        sed -i '/MY_WEBSOCKET_DOMAIN/a \
            \
            #!ifndef KAZOO_DB_URL
            #!substdef "!KAZOO_DB_URL!text:///volumes/ram/dbtext!g"
            #!endif' kamailio/local.cfg

		mv kamailio/* /etc/kamailio/
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
