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
	@docker exec -ti $(NAME) /bin/bash

run:
	@docker run -it --rm --name $(NAME) -h $(NAME).local --env-file run.env --entrypoint bash $(LOCAL_TAG)

launch:
	@docker run -d --name $(NAME) -h $(NAME).local --env-file default.env  --tmpfs /volumes/ram:size=32M $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME) -h $(NAME).local --env-file default.env -p "5060-5061:5060-5061" -p "5060:5060/udp" -p "5064-5065:5064-5065" -p "5064-5065:5064-5065/udp" -p "7000-7001:7000-7001" -p "7000:7000/udp" --network=local --net-alias --tmpfs /volumes/ram:size=32M $(NAME).local $(LOCAL_TAG)

launch-deps:
	-cd ../docker-rabbitmq && make launch-as-dep
	-cd ../docker-freeswitch && make launch-as-dep

create-network:
	@docker network create -d bridge local

proxies-up:
	@cd ../docker-aptcacher-ng && make remote-persist
	#@cd ../docker-squid && make remote-persist

dclean:
	@-docker ps -aq | gxargs -I{} docker rm {} 2> /dev/null || true
	@-docker images -f dangling=true -q | xargs docker rmi
	@-docker volume ls -f dangling=true -q | xargs docker volume rm

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