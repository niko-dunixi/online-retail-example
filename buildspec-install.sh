#!/usr/bin/env bash
set -ex

aws s3 cp \
  "s3://$(./pipeline/get-bootstrap-resource.sh --resource=s3)/tools/terraform_${TF_VERSION}_linux_amd64.zip" \
  /tmp/terraform.zip
unzip /tmp/terraform.zip -d /usr/local/bin && rm /tmp/terraform.zip
