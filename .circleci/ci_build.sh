#!/bin/sh -e
#
# Build the image with short ref of the current commit as its tag.
#

if ! command -v docker >/dev/null; then
    printf >&2 "Docker has not been installed.\\n"
    exit 1
fi

if ! command -v git >/dev/null; then
    printf >&2 "Git has not been installed.\\n"
    exit 1
fi


## Building
##

BASE_DIR=$(cd "$(dirname "$0")/.." || exit; pwd -P)
IMAGE_TAG=$(git rev-parse --short HEAD)

cd "$BASE_DIR" || exit 1
exec make docker IMAGE_TAG="$IMAGE_TAG"
