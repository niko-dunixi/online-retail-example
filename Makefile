.PHONY: fmt bootstrap deploy-pipeline destroy-pipeline trigger-pipeline deploy-application

AWS_REGION ?= ${AWS_REGION}

TERRAFORM_VERSION = 0.14.5

#TF = docker run --rm -it \
#	--env-file=.env \
#	--workdir=/main \
#	--volume /var/run/docker.sock:/var/run/docker.sock \
#	--volume $(shell pwd):/main \
#	--volume "$(HOME)/.aws:/root/.aws" \
#	build-env:latest terraform

#	--env TF_LOG=DEBUG \

TF := terraform

.env:
	./initialize-env.sh

fmt: .env
	$(MAKE) -C bootstrap fmt
	$(MAKE) -C pipeline fmt
	$(MAKE) -C store-api fmt
	$(TF) fmt

build-environment:
	docker build --tag build-env:latest ./docker-build-env

bootstrap: .env
	$(MAKE) -C bootstrap deploy

deploy-pipeline: .env
	$(MAKE) -C pipeline deploy

destroy-pipeline: .env
	$(MAKE) -C pipeline destroy

trigger-pipeline: .env
	$(MAKE) -C pipeline trigger

build-functions:
	$(MAKE) -C store-api

deploy-application:
	[ -d .terraform ] || $(TF) init \
		-backend-config "bucket=$(shell ./pipeline/get-bootstrap-resource.sh --resource=s3)" \
		-backend-config "dynamodb_table=$(shell ./pipeline/get-bootstrap-resource.sh --resource=dynamodb)" \
		-backend-config "region=${AWS_REGION}" \
		-backend-config "key=tfstate/managed/application.tf"
	$(TF) apply -auto-approve