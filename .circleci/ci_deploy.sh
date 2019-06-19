#!/bin/sh -e
#
# Authenticates with Kubernetes cluster and patch the deployment.
#

if ! command -v gcloud >/dev/null; then
    printf >&2 "Google Cloud SDK has not been installed.\\n"
    exit 1
fi

if ! command -v git >/dev/null; then
    printf >&2 "Git has not been installed.\\n"
    exit 1
fi

if ! command -v kubectl >/dev/null; then
    printf >&2 "Kubectl has not been installed.\\n"
    exit 1
fi


## Figure out latest image and tag
##

if [ -z "$IMAGE_NAME" ]; then
    printf >&2 "IMAGE_NAME has not been set.\\n"
    exit 1
fi

IMAGE_TAG=$(git rev-parse --short HEAD)


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

if [ -z "$GCP_REGION" ] || [ -z "$GCP_ZONE" ] || [ -z "$GCP_CLUSTER_ID" ]; then
    printf >&2 "Cluster credentials not present.\\n"
    exit 1
fi

gcloud config set compute/region "$GCP_REGION"
gcloud config set compute/zone "$GCP_ZONE"
gcloud container clusters get-credentials --region="$GCP_REGION" "$GCP_CLUSTER_ID"


## Deploy target
##

if [ -z "$DEPLOY_NS" ] || [ -z "$DEPLOY_NAME" ] || [ -z "$DEPLOY_CONTAINER" ]; then
    printf >&2 "Deploy target not present.\\n"
    exit 1
fi

cat <<EOF | kubectl patch --namespace="$DEPLOY_NS" deploy "$DEPLOY_NAME" -p "$(cat -)"
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "$DEPLOY_CONTAINER",
            "image": "$IMAGE_NAME:$IMAGE_TAG"
          }
        ]
      }
    }
  }
}
EOF
