#!/usr/bin/env bash
set -ex

function ecr-login() {
  aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
}

function ecr-logout() {
  docker logout AWS
}

# This _should_ have prevented the need to rebuild, but even without changes
# pulling the image first doesn't help.
#ecr-login
#[ "$(aws ecr list-images --repository-name "${ECR_NAME}" --query imageIds | jq length)" -eq 0 ] || docker pull "${ECR_URL}:latest"
#ecr-logout

docker build --tag "${ECR_URL}:latest" - < ./pipeline/codebuild.Dockerfile
#docker build --tag build-image:latest - < ./pipeline/codebuild.Dockerfile
#docker tag build-image:latest "${ECR_URL}:latest"
ecr-login
docker push "${ECR_URL}:latest"