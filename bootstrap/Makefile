.PHONY: validate_vars deploy fmt

TERRAFORM_VERSION =

TF = docker run --rm -it \
	--env-file=../.env \
	--workdir=/main \
	--volume $(shell pwd):/main \
	--volume "$(HOME)/.aws:/root/.aws" \
	hashicorp/terraform:$(TERRAFORM_VERSION)

validate_vars:
	@[ -f ../.env ] || (echo "You must initialize the .env file in the project directory" && false)
	@[ -n "$(TERRAFORM_VERSION)" ] || (echo "You must set TERRAFORM_VERSION" && false)

.terraform: validate_vars
	[ -d .terraform ] || $(TF) init

terraform_$(TERRAFORM_VERSION)_linux_amd64.zip:
	curl -JLO https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_linux_amd64.zip

deploy: validate_vars .terraform terraform_$(TERRAFORM_VERSION)_linux_amd64.zip
	./sync-bootstrap-state.sh --direction=down
	$(TF) apply -auto-approve || (./sync-bootstrap-state.sh --direction=up && false)
	./sync-bootstrap-state.sh --direction=up

fmt: validate_vars
	$(TF) fmt -recursive
