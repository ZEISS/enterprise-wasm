#!/bin/bash

set -eoux pipefail
source ../../helpers/common.sh

AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

REVISION=`date +"%s"`

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/warpwasi-dapr-rs:$REVISION
docker buildx build --provenance=false --push -t $IMAGE_NAME .
