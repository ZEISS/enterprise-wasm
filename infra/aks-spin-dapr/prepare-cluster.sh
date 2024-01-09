#!/bin/bash

set -e

REPO_ROOT=`git rev-parse --show-toplevel`

terraform output -raw kube_config > ~/.kube/config
RESOURCE_GROUP_NAME=`terraform output -json script_vars | jq -r .resource_group`

AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`

until [ ! -z $AZURE_CONTAINER_REGISTRY_NAME ];
do
  echo "wait 30 seconds for resources & AAD auth to be available"
  sleep 30
  AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
done

AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`

# ---- install Wasm Shims
wget -q -O- https://raw.githubusercontent.com/KWasm/kwasm-node-installer/main/example/daemonset.yaml | \
yq eval ".spec|=select(.selector.matchLabels.app==\"default-init\")
    .template.spec.nodeSelector.agentpool = \"backend\"" | \
kubectl apply -f -

kubectl apply -f ./runtimeclass.yaml
kubectl apply -f ./namespaces.yaml

# ---- make and build Dapr shared image
pushd $REPO_ROOT/../dapr-shared
make release
popd

az acr build --registry $AZURE_CONTAINER_REGISTRY_NAME \
  --image dapr-shared:latest \
  $REPO_ROOT/../dapr-shared/
