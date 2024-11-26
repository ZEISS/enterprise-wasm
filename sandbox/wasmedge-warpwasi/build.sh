#!/bin/bash

set -eoux pipefail
REPO_ROOT=~/src/enterprise-wasm
source <(cat $REPO_ROOT/.env)
RUNTIME=`echo $STACK | awk -F'-' '{print $1 "-" $2}'`
TARGET_INFRA_FOLDER=$REPO_ROOT/$INFRA_FOLDER
RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`

AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

REVISION=`date +"%s"`

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/http-server:$REVISION
docker buildx build --provenance=false --push -t $IMAGE_NAME .

