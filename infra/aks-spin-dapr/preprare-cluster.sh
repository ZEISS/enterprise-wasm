#!/bin/bash

set -e

REPO_ROOT=`git rev-parse --show-toplevel`
terraform output -raw kube_config > ~/.kube/config
RESOURCE_GROUP_NAME=`terraform output -json script_vars | jq -r .resource_group`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

# ---- use installer from repo to get Spin v2
az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/shim-install:latest

pushd $REPO_ROOT/../kwasm-node-installer/
docker build --push -t $IMAGE_NAME -f images/installer/Dockerfile .
popd

cat $REPO_ROOT/../kwasm-node-installer/example/daemonset.yaml | \
yq eval ".spec|=select(.selector.matchLabels.app==\"default-init\")
    .template.spec.initContainers[0].image = \"$IMAGE_NAME\"" | \
kubectl apply -f -
kubectl apply -f ./runtimeclass.yaml

# kubectl apply -f $REPO_ROOT/../kwasm-node-installer/example/debug.yaml
# kubectl -it kwasm-debug-5mfzs -- ls -l /mnt/node-root/opt/kwasm/bin

# # ---- make and build Dapr Ambient image
pushd $REPO_ROOT/../dapr-ambient
make release
popd

az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME \
  --image dapr-ambient:latest \
  $REPO_ROOT/../dapr-ambient/
