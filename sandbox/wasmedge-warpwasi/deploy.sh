#!/bin/bash

set -eoux pipefail
source ../../helpers/common.sh

APP=http-server
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`
TAG=`az acr repository show-tags -n $AZURE_CONTAINER_REGISTRY_NAME --repository $APP --top 1 --orderby time_desc -o tsv`
IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/$APP:$TAG

WORKLOAD=./workload-kn.yml
cat $WORKLOAD | \
yq eval ".|=select(.metadata.name==\"http-server\")
    .spec.template.spec.containers[0].image = \"$IMAGE_NAME\""  | \
kubectl apply -f -
