#!/bin/bash

set -e

REPO_ROOT=`git rev-parse --show-toplevel`
source <(cat $REPO_ROOT/.env)
TARGET_INFRA_FOLDER=$REPO_ROOT/$INFRA_FOLDER

RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

REVISION=`date +"%s"`

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/express-dapr-ts:$REVISION

if [[ "$STACK" =~ "-kn" ]]; then
  docker buildx create --use
  docker buildx build --platform=linux/amd64,linux/arm64 --push -t $IMAGE_NAME .
else
  docker build --push -t $IMAGE_NAME .
fi
