IMAGE_NAME?=	gcr.io/omise-go/potterhat
IMAGE_TAG?=	dev

.MAIN: docker

.PHONY: docker

docker:
	docker build . -t ${IMAGE_NAME}:${IMAGE_TAG}
