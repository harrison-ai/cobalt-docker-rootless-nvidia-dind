
.DEFAULT_GOAL := help
IMAGE_NAME := ghcr.io/harrison-ai/rootless-nvidia-dind:latest

## build:                       build the docker image
build:
	./scripts/build.sh $(IMAGE_NAME)

## publish:                     push the docker image to registry with the given TAG
publish:
	@test -n "${TAG}" || ( echo "TAG environment variable must be set" && return 1 )
	./scripts/publish.sh $(IMAGE_NAME) ${TAG}

## help:                        show this help
help:
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
