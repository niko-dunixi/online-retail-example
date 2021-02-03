version: 0.2

# We need to enable checking if the docker image doesn't exist, this is relevant on the
# first run. This is why DOCKER_CLI_EXPERIMENTAL is enabled, so we can make `docker manifest`
# commands available
# See: https://stackoverflow.com/a/52077346/1478636

env:
  shell: bash
  variables:
    #DOCKER_BUILDKIT: 1
    DOCKER_CLI_EXPERIMENTAL: enabled
    AWS_ACCOUNT_ID: ${aws_account_id}
    ECR_URL: ${ecr_url}
    ECR_NAME: ${ecr_name}

phases:
  build:
    commands:
      - ./pipeline/build-codebuild-image.sh