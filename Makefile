all: clean build-prod

IMAGE_NAME      ?= "omisego/potterhat:latest"
IMAGE_BUILDER   ?= "omisegoimages/ewallet-builder:stable"
IMAGE_BUILD_DIR ?= $(PWD)

ENV_DEV         ?= env MIX_ENV=dev
ENV_TEST        ?= env MIX_ENV=test
ENV_PROD        ?= env MIX_ENV=prod

LANG            := en_US.UTF-8
LC_ALL          := en_US.UTF-8

#
# Setting-up
#

deps:
	mix deps.get

.PHONY: deps

#
# Cleaning
#

clean:
	rm -rf _build/
	rm -rf deps/

.PHONY: clean

#
# Linting
#

format:
	mix format

check-format:
	mix format --check-formatted 2>&1

check-credo:
	$(ENV_TEST) mix credo 2>&1

check-dialyzer:
	$(ENV_TEST) mix dialyzer --halt-exit-status >&1

.PHONY: format check-format check-credo check-dialyzer

#
# Building
#

# If we call mix phx.digest without mix compile, mix release will silently fail
# for some reason. Always make sure to run mix compile first.
build-prod: deps
	$(ENV_PROD) mix do compile, release

build-dev: deps
	$(ENV_DEV) mix do compile, release dev

build-test: deps
	$(ENV_TEST) mix compile

.PHONY: build-prod build-dev build-test

#
# Testing
#

test: build-test
	$(ENV_TEST) mix do ecto.create, ecto.migrate, test

.PHONY: test

#
# Docker
#

docker-prod:
	docker run --rm -it \
		-v $(PWD):/app \
		-v $(IMAGE_BUILD_DIR)/deps:/app/deps \
		-u root \
		--entrypoint /bin/sh \
		$(IMAGE_BUILDER) \
		-c "cd /app && make build-prod"

docker-build:
	docker build \
		--build-arg release_version=$$(awk '/version:/ { gsub(/[^0-9a-z\.\-]+/, "", $$2); print $$2 }' $(PWD)/apps/potterhat_node/mix.exs) \
		--cache-from $(IMAGE_NAME) \
		-t $(IMAGE_NAME) \
		.

docker: docker-prod docker-build

docker-push: docker
	docker push $(IMAGE_NAME)

.PHONY: docker docker-prod docker-build docker-push
