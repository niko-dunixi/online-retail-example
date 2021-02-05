.PHONY: fmt bootstrap deploy-pipeline destroy-pipeline trigger-pipeline deploy-application

AWS_REGION ?= ${AWS_REGION}

TERRAFORM_VERSION = 0.14.5

TF = docker run --rm -it \
	--env-file=.env \
	--workdir=/main \
	--volume $(shell pwd):/main \
	--volume "$(HOME)/.aws:/root/.aws" \
	hashicorp/terraform:$(TERRAFORM_VERSION)

.env:
	./initialize-env.sh

fmt: .env
	$(MAKE) -C bootstrap fmt TERRAFORM_VERSION=$(TERRAFORM_VERSION)
	$(MAKE) -C pipeline fmt TERRAFORM_VERSION=$(TERRAFORM_VERSION)
	$(MAKE) -C store-api fmt
	$(TF) fmt

bootstrap: .env
	$(MAKE) -C bootstrap deploy TERRAFORM_VERSION=$(TERRAFORM_VERSION)

deploy-pipeline: .env
	$(MAKE) -C pipeline deploy TERRAFORM_VERSION=$(TERRAFORM_VERSION)

destroy-pipeline: .env
	$(MAKE) -C pipeline destroy TERRAFORM_VERSION=$(TERRAFORM_VERSION)

trigger-pipeline: .env
	$(MAKE) -C pipeline trigger TERRAFORM_VERSION=$(TERRAFORM_VERSION)

build-functions:
	$(MAKE) -C store-api

deploy-application:
	[ -d .terraform ] || $(TF) init \
		-backend-config "bucket=$(shell ./pipeline/get-bootstrap-resource.sh --resource=s3)" \
		-backend-config "dynamodb_table=$(shell ./pipeline/get-bootstrap-resource.sh --resource=dynamodb)" \
		-backend-config "region=${AWS_REGION}" \
		-backend-config "key=tfstate/managed/application.tf"
	$(TF) apply -auto-approve