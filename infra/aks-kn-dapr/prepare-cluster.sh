#!/bin/bash

set -eoux pipefail

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

KNATIVE_VERSION=1.13.1
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v$KNATIVE_VERSION/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v$KNATIVE_VERSION/serving-core.yaml
kubectl apply -f https://github.com/knative/net-kourier/releases/latest/download/kourier.yaml
kubectl patch configmap/config-network \
  -n knative-serving \
  --type merge \
  -p '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'
kubectl patch configmap/config-domain \
  -n knative-serving \
  --type merge \
  -p '{"data":{"127.0.0.1.sslip.io":""}}'
