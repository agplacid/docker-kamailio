# Kamailio w/ Kubernetes fixes & manifests

[![Build Status](https://travis-ci.org/sip-li/docker-kamailio.svg?branch=master)](https://travis-ci.org/sip-li/docker-kamailio) [![Docker Pulls](https://img.shields.io/docker/pulls/callforamerica/kamailio.svg)](https://hub.docker.com/r/callforamerica/kamailio) [![Size/Layers](https://images.microbadger.com/badges/image/callforamerica/kamailio.svg)](https://microbadger.com/images/callforamerica/kamailio)

## Maintainer
Joe Black | <joe@valuphone.com> | [github](https://github.com/joeblackwaslike)


## Description
Minimal kamailio image with enhancements including running frequently accessed files off of a tmpfs volume.  This image uses a custom version of Debian Linux (Jessie) that I designed weighing in at ~22MB compressed.


## Build Environment
Build environment variables are often used in the build script to bump version numbers and set other options during the docker build phase.  Their values can be overridden using a build argument of the same name.
* `KAMAILIO_VERSION`
* `KAMAILIO_INSTALL_MODS`
* `KAZOO_CONFIGS_BRANCH`

The following variables are standard in most of our dockerfiles to reduce duplication and make scripts reusable among different projects:
* `APP`: kamailio
* `USER`: kamailio
* `HOME` /opt/kamailio


## Run Environment
Run environment variables are used in the entrypoint script to render configuration templates, perform flow control, etc.  These values can be overridden when inheriting from the base dockerfile, specified during `docker run`, or in kubernetes manifests in the `env` array.

* `PUBLIC_IPV4`
* `PUBLIC_FQDN`
* `DOMAIN_NAME`
* `KAMAILIO_LOG_LEVEL`
* `KAMAILIO_LOG_COLOR`
* `KAMAILIO_MY_HOSTNAME`
* `KAMAILIO_MY_IP_ADDRESS`
* `KAMAILIO_MY_WEBSOCKET_DOMAIN`
* `KAMAILIO_AMQP_HOSTS`
* `RABBITMQ_USER`
* `RABBITMQ_PASS`
* `KAMAILIO_SHM_MEMORY`
* `KAMAILIO_PKG_MEMORY`
* `KAMAILIO_CHILD_PROC`
* `KAMAILIO_MTU`
* `KAMAILIO_ENABLE_ROLES`
* `SYNC_FREESWITCH_SOURCE`
* `SYNC_FREESWITCH_ARGS`

[todo] Finish describing these.


## Usage
### Under docker (pre-built)
All of our docker-* repos in github have CI pipelines that push to docker cloud/hub.  

This image is available at:
* [https://store.docker.com/community/images/callforamerica/kamailio](https://store.docker.com/community/images/callforamerica/kamailio)
*  [https://hub.docker.com/r/callforamerica/kamailio](https://hub.docker.com/r/callforamerica/kamailio).
* `docker pull callforamerica/kamailio`

To run:

```bash
docker run -d \
    --name kamailio \
    -h kamailio.example.local \
    -p "5060-5061:5060-5061" \
    -p "5060:5060/udp" \
    -p "5064-5065:5064-5065" \
    -p "5064-5065:5064-5065/udp" \
    -p "7000-7001:7000-7001" \
    -p "7000:7000/udp" \
    -e "KAMAILIO_LOG_LEVEL=info" \
    -e  "KAMAILIO_ENABLE_ROLES=websockets,message,presence_query,presence_sync,presence_notify_sync,registrar_sync" \
    -e "KAMAILIO_AMQP_HOSTS=rabbitmq-alpha.local,rabbitmq-beta.local" \
    -e "SYNC_FREESWITCH_SOURCE=dns" \
    -e "SYNC_FREESWITCH_ARGS=freeswitch.local" \
    --cap-add IPC_LOCK \
    --cap-add SYS_NICE \
    --cap-add SYS_RESOURCE \
    --cap-add NET_RAW \
    callforamerica/kamailio
```

**NOTE:** Please reference the Run Environment section for the list of available environment variables.

**NOTE:** In production, you may want to run this container in the host's networking stack.  In that case remove the port mappings above and insert `--net=host`.  Under Kubernetes, if you are using our manifests, this is already taken care of.


### Under docker-compose
Pull the images
```bash
docker-compose pull
```

Start application and dependencies
```bash
# start in foreground
docker-compose up --abort-on-container-exit

# start in background
docker-compose up -d
```


### Under Kubernetes
Edit the manifests under `kubernetes/<environment>` to reflect your specific environment and configuration.

Create a secret for the erlang cookie:
```bash
kubectl create secret generic erlang-cookie --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

Create a secret for the kamailio credentials:
```bash
kubectl create secret generic kamailio-creds --from-literal=kamailio.user=$(sed $(perl -e "print int rand(99999)")"q;d" /usr/share/dict/words) --from-literal=kamailio.pass=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 32)
```

Deploy kamailio:
```bash
kubectl create -f kubernetes
```
