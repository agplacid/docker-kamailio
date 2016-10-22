NS = vp
NAME = kamailio
APP_VERSION = 4.4.3
IMAGE_VERSION = 2.0
VERSION = $(APP_VERSION)-$(IMAGE_VERSION)
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME):$(VERSION)

GITHUB_REPO = docker-kamailio
DOCKER_REPO = kamailio
BUILD_BRANCH = master

VOLUME_ARGS = --tmpfs /volumes/ram:size=32M -v "$(PWD)/tls:/volumes/tls"
ENV_ARGS = --env-file default.env
PORT_ARGS = -p "5060-5061:5060-5061" -p "5060:5060/udp" -p "5064-5065:5064-5065" -p "5064-5065:5064-5065/udp" -p "7000-7001:7000-7001" -p "7000:7000/udp"
CAP_ARGS = --cap-add IPC_LOCK --cap-add SYS_NICE --cap-add SYS_RESOURCE --cap-add NET_ADMIN --cap-add NET_RAW --cap-add NET_BROADCAST
SHELL = bash -l

-include ../Makefile.inc

.PHONY: all build test release shell run start stop rm rmi default

all: build

checkout:
	@git checkout $(BUILD_BRANCH)

build:
	@docker build -t $(LOCAL_TAG) --force-rm .
	$(MAKE) tag
	$(MAKE) dclean

tag:
	@docker tag $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --force-rm --no-cache .

test:
	@rspec ./tests/*.rb

commit:
	@git add -A .
	@git commit

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) $(SHELL)

run:
	@docker run -it --rm --name $(NAME) -h $(NAME).local --env-file run.env $(VOLUME_ARGS) $(CAP_ARGS) $(LOCAL_TAG) $(SHELL)

launch:
	@docker run -d --name $(NAME) -h $(NAME).local $(ENV_ARGS) $(VOLUME_ARGS) $(PORT_ARGS) $(CAP_ARGS) $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME) -h $(NAME).local $(ENV_ARGS) $(VOLUME_ARGS) $(PORT_ARGS) $(CAP_ARGS) --network local --net-alias $(NAME).local $(LOCAL_TAG)

launch-deps:
	-cd ../docker-rabbitmq && make launch-as-dep
	-cd ../docker-freeswitch && make launch-as-dep

rmf-deps:
	-cd ../docker-rabbitmq && make rmf-as-dep
	-cd ../docker-freeswitch && make rmf-as-dep

launch-dev:
	@$(MAKE) launch-net

rmf-dev:
	@$(MAKE) rmf

launch-as-dep:
	@$(MAKE) launch-net

rmf-as-dep:
	@$(MAKE) rmf

create-network:
	@docker network create -d bridge local

proxies-up:
	@cd ../docker-aptcacher-ng && make remote-persist
	#@cd ../docker-squid && make remote-persist

# dclean:
# 	@-docker ps -aq | gxargs -I{} docker rm {} 2> /dev/null || true
# 	@-docker images -f dangling=true -q | xargs docker rmi
# 	@-docker volume ls -f dangling=true -q | xargs docker volume rm

logs:
	@docker logs $(NAME)

logsf:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	@docker kill $(NAME)

stop:
	@docker stop $(NAME)

rm:
	@docker rm $(NAME)

rmf:
	@docker rm -f $(NAME)

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

kube-deploy:
	@kubectl create -f kubernetes/$(NAME)-deployment.yaml --record

kube-deploy-daemonset:
	@kubectl create -f kubernetes/$(NAME)-daemonset.yaml

kube-edit-daemonset:
	@kubectl edit daemonset/$(NAME)

kube-delete-daemonset:
	@kubectl delete daemonset/$(NAME)

kube-deploy-service:
	@kubectl create -f kubernetes/$(NAME)-service.yaml

kube-delete-service:
	@kubectl delete svc $(NAME)

kube-replace-service:
	@kubectl replace -f kubernetes/$(NAME)-service.yaml

kube-logsf:
	@kubectl logs -f $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-logsft:
	@kubectl logs -f --tail=25 $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-shell:
	@kubectl exec -ti $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1) -- bash

default: build