NS = vp
NAME = kamailio
APP_VERSION = 4.3.4
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
	@docker build -t $(LOCAL_TAG) --rm .
	$(MAKE) tag

tag:
	@docker tag $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --rm --no-cache .

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
	@docker run -it --rm --name $(NAME) -e "ENVIRONMENT=local" -e "KAMAILIO_LOG_LEVEL=debug" --network=local --entrypoint bash $(LOCAL_TAG)

launch:
	@docker run -d --name $(NAME) -e "ENVIRONMENT=local" -p "5060:5060" $(LOCAL_TAG)

launch-net:
	@docker run -d -h $(NAME) --name $(NAME) -e "ENVIRONMENT=local" -e "KAMAILIO_LOG_LEVEL=debug" --network=local $(LOCAL_TAG)

launch-deps:
	-cd ../docker-rabbitmq && make launch-net
	-cd ../docker-freeswitch && make launch-net

create-network:
	@docker network create -d bridge local

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

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

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

default: build