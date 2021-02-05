.PHONY: build

export GO111MODULE ?= ${GO111MODULE:-on}
export DOCKER_BUILDKIT=1

build:
	docker build --tag creation-function:latest --target creation-function .

fmt:
	go fmt ./...
