.PHONY: validate_vars deploy fmt

TF_VARFILE ?= defaults.tfvars

TF := terraform

validate_vars:
	@[ -f ../.env ] || (echo "You must initialize the .env file in the project directory" && false)

.terraform: validate_vars
	[ -d .terraform ] || $(TF) init \
		-backend-config "bucket=$(shell ./get-bootstrap-resource.sh --resource=s3)" \
		-backend-config "dynamodb_table=$(shell ./get-bootstrap-resource.sh --resource=dynamodb)" \
		-backend-config "region=$(shell grep AWS_REGION ../.env | sed -e "s/^.*=//")" \
		-backend-config "key=tfstate/managed/pipeline.tf"

deploy: validate_vars .terraform
	$(TF) apply \
		-var bootstrap_bucket_name="$(shell ./get-bootstrap-resource.sh --resource=s3)" \
		-var-file=$(TF_VARFILE) \
		-auto-approve

destroy: validate_vars .terraform
	$(TF) destroy -var-file=$(TF_VARFILE)

trigger: validate_vars .terraform
	./trigger-pipeline.sh --codepipeline-name=$(shell $(TF) output codepipeline_name)

fmt: validate_vars
	$(TF) fmt -recursive
