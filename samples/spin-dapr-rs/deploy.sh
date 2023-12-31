#!/bin/bash

REPO_ROOT=`git rev-parse --show-toplevel`
TARGET_INFRA_FOLDER=../../infra/aks-spin-dapr
RESOURCE_GROUP_NAME=`terraform output -state=$TARGET_INFRA_FOLDER/terraform.tfstate -json script_vars | jq -r .resource_group`

APP=spin-dapr-rs
SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
STORAGE_ACCOUNT_KEY=`az storage account keys list -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME --query "[?permissions == 'FULL'] | [0].value" -o tsv `
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`
TAG=`az acr repository show-tags -n $AZURE_CONTAINER_REGISTRY_NAME --repository $APP --top 1 --orderby time_desc -o tsv`
IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/$APP:$TAG

PATTERN="${1:-ambient}"

kubectl delete secret servicebus-secret --ignore-not-found
kubectl create secret generic servicebus-secret --from-literal=connectionString=$SERVICEBUS_CONNECTION
kubectl delete secret storage-secret --ignore-not-found
kubectl create secret generic storage-secret --from-literal=accountName=$STORAGE_NAME \
    --from-literal=accountKey=$STORAGE_ACCOUNT_KEY

kubectl apply -f ./dapr-components.yml

cat ./workload-aks-$PATTERN.yml | \
yq eval ".spec|=select(.selector.matchLabels.app==\"distributor\")
    .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
yq eval ".spec|=select(.selector.matchLabels.app==\"receiver-express\") 
    .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
yq eval ".spec|=select(.selector.matchLabels.app==\"receiver-standard\")
    .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
kubectl apply -f -

if [ $PATTERN = 'ambient' ]; then
  apps=("distributor")
  # apps=("distributor" "receiver-express" "receiver-standard")

  for app in "${apps[@]}"
  do
    echo "$app"

    helm upgrade --install $app-dapr $REPO_ROOT/../dapr-ambient/chart/dapr-ambient/ \
      --set fullnameOverride=$app-dapr \
      --set ambient.initContainer.image.registry=$AZURE_CONTAINER_REGISTRY_ENDPOINT \
      --set ambient.daprd.image.tag=1.11.6 \
      --set ambient.appId=$app \
      --set ambient.remoteURL=$app-svc \
      --set ambient.remotePort=80 \
      --set ambient.serviceAccount.name=$app \
      --set ambient.daprd.listenAddresses=127.0.0.1

      # --set ambient.controlPlane.sentryAddress=dapr-sentry.dapr-system.svc.cluster.local:80

  done
fi
