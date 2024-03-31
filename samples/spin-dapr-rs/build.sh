#!/bin/bash

set -e

REPO_ROOT=`git rev-parse --show-toplevel`
source <(cat $REPO_ROOT/.env)
RUNTIME=`echo $STACK | awk -F'-' '{print $1 "-" $2}'`
TARGET_INFRA_FOLDER=$REPO_ROOT/$INFRA_FOLDER

RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`
AZURE_CONTAINER_REGISTRY_PASSWORD=`az acr credential show -n $AZURE_CONTAINER_REGISTRY_NAME --query "passwords[0].value" -o tsv`

REVISION=`date +"%s"`

if [ "$1" == "docker" ]; then

  az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

  if [[ -z $(docker buildx ls | grep wasm-builder) ]]; then
    docker buildx create --name wasm-builder --platform wasi/wasm,linux/amd64
  fi

  IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/spin-dapr-rs:$REVISION

  docker buildx use wasm-builder
  docker buildx build --platform=wasi/wasm --provenance=false --push -t $IMAGE_NAME .
  docker buildx use default

else

  spin registry login -u $AZURE_CONTAINER_REGISTRY_NAME -p $AZURE_CONTAINER_REGISTRY_PASSWORD $AZURE_CONTAINER_REGISTRY_ENDPOINT
  spin registry push --build $AZURE_CONTAINER_REGISTRY_ENDPOINT/spin-dapr-rs:$REVISION

fi

