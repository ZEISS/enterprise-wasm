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

cargo build --target wasm32-wasi --release
wasmedge compile target/wasm32-wasi/release/warpwasi_dapr_rs.wasm target/warpwasi_dapr_rs.wasm

if [[ -z $(docker buildx ls | grep wasm-builder) ]]; then
  docker buildx create --name wasm-builder --platform wasi/wasm,linux/amd64
fi

IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/warpwasi-dapr-rs:$REVISION

docker buildx use wasm-builder
docker buildx build --platform=wasi/wasm --provenance=false --push -t $IMAGE_NAME .
docker buildx use default
