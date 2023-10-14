.PHONY: all
all: docker

VERSION ?= $(shell git describe --always --dirty --tags 2>/dev/null || echo "undefined")
REGISTRY ?= ghcr.io/charbonnierg
REPOSITORY ?= demo-dynamic-matrix

DOCKER_BUILD_PLATFORM         ?= linux/amd64,linux/arm64,linux/ppc64le,linux/arm/v6,linux/arm/v7
DOCKER_BUILD_RUNTIME_IMAGE    ?= alpine:3.18
DOCKER_BUILDX_ARGS            ?= --build-arg RUNTIME_IMAGE=${DOCKER_BUILD_RUNTIME_IMAGE}
DOCKER_BUILDX                 := docker buildx build ${DOCKER_BUILDX_ARGS} --build-arg VERSION=${VERSION}
DOCKER_BUILDX_X_PLATFORM      := $(DOCKER_BUILDX) --platform ${DOCKER_BUILD_PLATFORM}
DOCKER_BUILDX_PUSH            := $(DOCKER_BUILDX) --push
DOCKER_BUILDX_PUSH_X_PLATFORM := $(DOCKER_BUILDX_PUSH) --platform ${DOCKER_BUILD_PLATFORM}

.PHONY: docker
docker:
	$(DOCKER_BUILDX_X_PLATFORM) -t $(REGISTRY)/oauth2-proxy:latest -t $(REGISTRY)/oauth2-proxy:${VERSION} .

.PHONY: docker-all
docker-all: docker
	$(DOCKER_BUILDX) --platform linux/amd64   -t $(REGISTRY)/oauth2-proxy:latest-amd64   -t $(REGISTRY)/oauth2-proxy:$(VERSION)-amd64 .
	$(DOCKER_BUILDX) --platform linux/arm64   -t $(REGISTRY)/oauth2-proxy:latest-arm64   -t $(REGISTRY)/oauth2-proxy:$(VERSION)-arm64 .
	$(DOCKER_BUILDX) --platform linux/ppc64le -t $(REGISTRY)/oauth2-proxy:latest-ppc64le -t $(REGISTRY)/oauth2-proxy:$(VERSION)-ppc64le .
	$(DOCKER_BUILDX) --platform linux/arm/v6  -t $(REGISTRY)/oauth2-proxy:latest-armv6   -t $(REGISTRY)/oauth2-proxy:$(VERSION)-armv6 .
	$(DOCKER_BUILDX) --platform linux/arm/v7  -t $(REGISTRY)/oauth2-proxy:latest-armv7   -t $(REGISTRY)/oauth2-proxy:$(VERSION)-armv7 .

.PHONY: docker-push
docker-push:
	$(DOCKER_BUILDX_PUSH_X_PLATFORM) -t $(REGISTRY)/$(REPOSITORY):latest -t $(REGISTRY)/$(REPOSITORY):$(VERSION) .

