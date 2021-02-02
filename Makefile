.PHONY: fmt bootstrap

TERRAFORM_VERSION = 0.14.5

.env:
	./initialize-env.sh

fmt: .env
	$(MAKE) -C bootstrap fmt TERRAFORM_VERSION=0.14.5
	$(MAKE) -C pipeline fmt TERRAFORM_VERSION=0.14.5

bootstrap: .env
	$(MAKE) -C bootstrap deploy TERRAFORM_VERSION=0.14.5

deploy-pipeline: .env
	$(MAKE) -C pipeline deploy TERRAFORM_VERSION=0.14.5

destroy-pipeline: .env
	$(MAKE) -C pipeline destroy TERRAFORM_VERSION=0.14.5

trigger-pipeline: .env
	$(MAKE) -C pipeline trigger TERRAFORM_VERSION=0.14.5