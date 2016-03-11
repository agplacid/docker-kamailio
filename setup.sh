#!/bin/bash

set -e

echo "Creating user and group for kamailio ..."
groupadd kamailio
useradd --home-dir /var/lib/kamailio --shell /bin/bash --comment 'kamailio user' -g kamailio --create-home kamailio

# add 2600hz yum repos
echo "Creating /etc/yum.repos.d/2600hz.repo ..."
cat <<-EOF > /etc/yum.repos.d/2600hz.repo
	[2600hz_base_staging]
	name=2600hz-$releasever - Base Staging
	baseurl=http://repo.2600hz.com/Staging/CentOS_6/x86_64/Base/
	gpgcheck=0
	enabled=1

	[2600hz_R15B_staging]
	name=2600hz-$releasever - R15B Staging
	baseurl=http://repo.2600hz.com/Staging/CentOS_6/x86_64/R15B/
	gpgcheck=0
	enabled=1
EOF

echo "Installing kamailio ..."
yum -y update
yum -y install bind-utils
yum -y install kazoo-kamailio

echo "Installing JQ ..."
curl -o /usr/local/bin/jq -sSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x /usr/local/bin/jq

echo "configuring logging to stderr"
echo 'log_stderror = yes' >> /etc/kazoo/kamailio/local.cfg


echo "Creating Directories ..."
mkdir -p /var/lib/kamailio/bin
mkdir -p /var/run/kamailio
mkdir -p /tmp/kamailio


echo "Writing Hostname override fix ..."
tee /var/lib/kamailio/bin/hostname-fix <<'EOF'
#!/bin/bash

fqdn() {
	local IP=$(/bin/hostname -i | sed 's/\./-/g')
	local DOMAIN='default.pod.cluster.local'
	echo "${IP}.${DOMAIN}"
}

short() {
	local IP=$(/bin/hostname -i | sed 's/\./-/g')
	echo $IP
}

ip() {
	/bin/hostname -i
}

if [[ "$1" == "-f" ]]; then
	fqdn
elif [[ "$1" == "-s" ]]; then
	short
elif [[ "$1" == "-i" ]]; then
	ip
else
	short
fi
EOF
chmod +x /var/lib/kamailio/bin/hostname-fix


echo "Writing .bashrc ..."
tee ~/.bashrc <<'EOF'
#!/bin/bash

if [ "$KUBERNETES_HOSTNAME_FIX" == true ]; then
    if [ "$KAMAILIO_USE_LONGNAME" == true ]; then
        export HOSTNAME=$(hostname -f)
    else
        export HOSTNAME=$(hostname)
    fi
fi
EOF
chown kamailio:kamailio ~/.bashrc


echo "Setting Ownership & Permissions ..."

# /etc/kamailio
chown -R kamailio:kamailio /etc/kazoo/kamailio
find /etc/kazoo/kamailio -type f -exec chmod 0644 {} \;
find /etc/kazoo/kamailio -type d -exec chmod 0755 {} \;

# /etc/kamailio/certs
chown -R kamailio:kamailio /etc/kazoo/kamailio/certs
find /etc/kazoo/kamailio/certs -type f -exec chmod 0644 {} \;
find /etc/kazoo/kamailio/certs -type d -exec chmod 0755 {} \;

# /etc/kamailio/dbtext
chown -R kamailio:kamailio /etc/kazoo/kamailio/dbtext
find /etc/kazoo/kamailio/dbtext -type f -exec chmod 0644 {} \;
find /etc/kazoo/kamailio/dbtext -type d -exec chmod 0755 {} \;

# /usr/lib64/kamailio
chown -R root:root /usr/lib64/kamailio
find /usr/lib64/kamailio -type f -exec chmod 0766 {} \;
find /usr/lib64/kamailio -type d -exec chmod 0755 {} \;

# /var/run/kamailio
chown -R kamailio:kamailio /var/run/kamailio
find /var/run/kamailio -type f -exec chmod 0660 {} \;
find /var/run/kamailio -type d -exec chmod 0770 {} \;

# /tmp/kamailio
chown -R kamailio:kamailio /tmp/kamailio
chmod -R 0777 /tmp/kamailio


echo "Cleaning up ..."
yum clean all
rm -r /tmp/setup.sh
