#!/bin/bash

set -e

REPO_ROOT=`git rev-parse --show-toplevel`
terraform output -raw kube_config > ~/.kube/config
RESOURCE_GROUP_NAME=`terraform output -json script_vars | jq -r .resource_group`
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

#-- this does not get spin-v2 installed ...
# helm upgrade --install spin-containerd-shim-installer oci://ghcr.io/fermyon/charts/spin-containerd-shim-installer \
#   -n kube-system \
#   --version 0.10.0 \
#   --values ../../spin-k8s-bench/manifests/spin-values.yaml

#-- ... hence install from repo
az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME \
  --image shim-install:latest \
  $REPO_ROOT/../spin-containerd-shim-installer/image/

# make and build Dapr Ambient image
pushd $REPO_ROOT/../dapr-ambient
make release
popd

az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME \
  --image dapr-ambient:latest \
  $REPO_ROOT/../dapr-ambient/

# install Spin ContainerD Shim from local chart with own image
helm upgrade --install spin-containerd-shim-installer $REPO_ROOT/../spin-containerd-shim-installer/chart \
  -n kube-system \
  --set image.registry=$AZURE_CONTAINER_REGISTRY_ENDPOINT \
  --set image.repository=shim-install \
  --set image.tag=latest 
