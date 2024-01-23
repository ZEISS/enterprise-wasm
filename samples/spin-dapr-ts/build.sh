#!/bin/bash

set -e

TARGET_INFRA_FOLDER=../../infra/aks-spin-dapr
RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

REVISION=`date +"%s"`

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

if [[ -z $(docker buildx ls | grep wasm-builder) ]]; then
  docker buildx create --name wasm-builder --platform wasi/wasm,linux/amd64
fi

IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/spin-dapr-ts:$REVISION

docker buildx use wasm-builder
docker buildx build --platform=wasi/wasm --provenance=false --push -t $IMAGE_NAME .
docker buildx use default
