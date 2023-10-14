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
	$(DOCKER_BUILDX_X_PLATFORM) -t $(REGISTRY)/$(REPOSITORY):latest -t $(REGISTRY)/$(REPOSITORY):${VERSION} .

.PHONY: docker-all
docker-all: docker
	$(DOCKER_BUILDX) --platform linux/amd64   -t $(REGISTRY)/$(REPOSITORY):latest-amd64   -t $(REGISTRY)/$(REPOSITORY):$(VERSION)-amd64 .
	$(DOCKER_BUILDX) --platform linux/arm64   -t $(REGISTRY)/$(REPOSITORY):latest-arm64   -t $(REGISTRY)/$(REPOSITORY):$(VERSION)-arm64 .
	$(DOCKER_BUILDX) --platform linux/ppc64le -t $(REGISTRY)/$(REPOSITORY):latest-ppc64le -t $(REGISTRY)/$(REPOSITORY):$(VERSION)-ppc64le .
	$(DOCKER_BUILDX) --platform linux/arm/v6  -t $(REGISTRY)/$(REPOSITORY):latest-armv6   -t $(REGISTRY)/$(REPOSITORY):$(VERSION)-armv6 .
	$(DOCKER_BUILDX) --platform linux/arm/v7  -t $(REGISTRY)/$(REPOSITORY):latest-armv7   -t $(REGISTRY)/$(REPOSITORY):$(VERSION)-armv7 .

.PHONY: docker-push
docker-push:
	$(DOCKER_BUILDX_PUSH_X_PLATFORM) -t $(REGISTRY)/$(REPOSITORY):latest -t $(REGISTRY)/$(REPOSITORY):$(VERSION) .

.PHONY: docker-push-all
docker-push-all: docker-push
	$(DOCKER_BUILDX_PUSH) --platform linux/amd64   -t $(REGISTRY)/$(REPOSITORY):latest-amd64   -t $(REGISTRY)/$(REPOSITORY):${VERSION}-amd64 .
	$(DOCKER_BUILDX_PUSH) --platform linux/arm64   -t $(REGISTRY)/$(REPOSITORY):latest-arm64   -t $(REGISTRY)/$(REPOSITORY):${VERSION}-arm64 .
	$(DOCKER_BUILDX_PUSH) --platform linux/ppc64le -t $(REGISTRY)/$(REPOSITORY):latest-ppc64le -t $(REGISTRY)/$(REPOSITORY):${VERSION}-ppc64le .
	$(DOCKER_BUILDX_PUSH) --platform linux/arm/v6  -t $(REGISTRY)/$(REPOSITORY):latest-armv6   -t $(REGISTRY)/$(REPOSITORY):${VERSION}-armv6 .
	$(DOCKER_BUILDX_PUSH) --platform linux/arm/v7  -t $(REGISTRY)/$(REPOSITORY):latest-armv7   -t $(REGISTRY)/$(REPOSITORY):${VERSION}-armv7 .

