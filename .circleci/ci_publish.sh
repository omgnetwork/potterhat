#!/bin/sh -e
#
# Authenticates with Google Cloud CLI and publish the image to gcr.io.
#

if ! command -v docker >/dev/null; then
    printf >&2 "Docker has not been installed.\\n"
    exit 1
fi

if ! command -v gcloud >/dev/null; then
    printf >&2 "Google Cloud SDK has not been installed.\\n"
    exit 1
fi

if ! command -v git >/dev/null; then
    printf >&2 "Git has not been installed.\\n"
    exit 1
fi


## Figure out latest image and tags
##

if [ -z "$IMAGE_NAME" ]; then
    printf >&2 "IMAGE_NAME has not been set.\\n"
    exit 1
fi

IMAGE_TAGS=$(git rev-parse --short HEAD)

if [ "$(git rev-parse --abbrev-ref HEAD)" = "master" ]; then
    docker tag "$IMAGE_NAME:$IMAGE_TAGS" "$IMAGE_NAME:latest"
    IMAGE_TAGS="$IMAGE_TAGS latest"
fi


## Authenticate with Google Cloud SDK
##

if [ -z "$GCP_KEY_FILE" ] || [ -z "$GCP_ACCOUNT_ID" ]; then
    printf >&2 "Deploy credentials not present.\\n"
    exit 1
fi

GCPFILE=$(mktemp)
trap 'rm -f $GCPFILE' 0 1 2 3 6 14 15
echo "$GCP_KEY_FILE" | base64 -d > "$GCPFILE"

gcloud auth activate-service-account --key-file="$GCPFILE"
gcloud config set project "$GCP_ACCOUNT_ID"
gcloud auth configure-docker


## Publish
##

for TAG in $IMAGE_TAGS; do
    docker push "$IMAGE_NAME:$TAG"
done
