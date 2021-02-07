.PHONY: build

export GO111MODULE ?= ${GO111MODULE:-on}
export DOCKER_BUILDKIT=1

GO = docker run --rm -it \
	--env-file=.env \
	--workdir=/main \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--volume $(shell pwd):/main \
	--volume "$(HOME)/.aws:/root/.aws" \
	build-env:latest go

build:
	docker build --tag creation-function:latest --target creation-function .

fmt:
	$(GO) fmt ./...
