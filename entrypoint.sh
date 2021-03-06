#!/bin/bash

# Fail on error and undefined vars
set -eu

GCLOUD_TOKEN=$1
CLUSTER_NAME=$2
ZONE=$3
PROJECT_ID=$4
IMAGE_NAME=$5
GITHUB_REF=$6
GITHUB_SHA=$7
NAMESPACES=$8

# No prompt for gcloud installation
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

if [ -z "${GCLOUD_TOKEN}" ]; then echo "::error ::Undefined GCLOUD_TOKEN" && exit 1; fi
if [ -z "${CLUSTER_NAME}" ]; then echo "::error ::Undefined CLUSTER_NAME" && exit 1; fi
if [ -z "${ZONE}" ]; then echo "::error ::Undefined ZONE" && exit 1; fi
if [ -z "${PROJECT_ID}" ]; then echo "::error ::Undefined PROJECT_ID" && exit 1; fi
if [ -z "${IMAGE_NAME}" ]; then echo "::error ::Undefined IMAGE_NAME" && exit 1; fi
if [ -z "${GITHUB_REF}" ]; then echo "::error ::Undefined GITHUB_REF" && exit 1; fi
if [ -z "${GITHUB_SHA}" ]; then echo "::error ::Undefined GITHUB_SHA" && exit 1; fi
if [ -z "${NAMESPACES}" ]; then echo "::error ::Undefined NAMESPACES" && exit 1; fi

BUILD_VERSION=${GITHUB_SHA}

echo GITHUB_REF
echo "$GITHUB_REF"

if [[ "$GITHUB_REF" == *"refs/tags/"* ]]; then
  echo "triggered by tag"
  BUILD_VERSION=${GITHUB_REF/refs\/tags\//}
else
    if [[ "$GITHUB_REF" != *"refs/"* ]]; then
      echo "triggered by tag creation"
      BUILD_VERSION=${GITHUB_REF}
    else
      echo "triggered by push"
    fi
fi

echo BUILD_VERSION
echo "$BUILD_VERSION"

export PROJECT_ID=$PROJECT_ID
export IMAGE_NAME=$IMAGE_NAME
export BUILD_VERSION=$BUILD_VERSION

configure_kubectl(){
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin/kubectl
}

init_cloud(){
    if [ ! -d ${HOME}/google-cloud-sdk ]; then
        curl https://sdk.cloud.google.com | bash
        # to add the Google Cloud SDK command line tools to your $PATH
        source ${HOME}/google-cloud-sdk/path.bash.inc
    fi

    echo "${GCLOUD_TOKEN}" | base64 -d > client-secret.json

    gcloud auth activate-service-account --key-file client-secret.json

    echo "Authenticate Docker daemon to Google Cloud Registry"
    docker login -u _json_key --password-stdin https://eu.gcr.io < client-secret.json

    configure_kubectl

    # Set the correct project to deploy to
    gcloud config set project "$PROJECT_ID"
    gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

    echo "kubectl successfully configured for cluster $CLUSTER_NAME in $ZONE / $PROJECT_ID"
    echo "Initialization successfully done"
}

deployNamespace(){
  echo "Deploying on namespace [ $1 ]"

  for file in k8s/$1/*.yml; do
    echo dry-run [ $file ]
    kubectl apply --namespace=$1 --dry-run -f $file
    echo deployment [ $file ]
    envsubst < $file | kubectl apply --namespace=$1 -f -
  done
}

# ==============================================================================
# Fire up
# ==============================================================================

init_cloud

IFS=':'; arrNS=($NAMESPACES); unset IFS;

for i in $arrNS
do
 deployNamespace $i
done


