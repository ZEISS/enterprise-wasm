#!/bin/bash

source ../../helpers/common.sh
get_deployment_configuration ${1:-shared}

APP=warpwasi-dapr-rs
SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
STORAGE_ACCOUNT_KEY=`az storage account keys list -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME --query "[?permissions == 'FULL'] | [0].value" -o tsv `
AZURE_CONTAINER_REGISTRY_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerRegistry/registries --query '[0].name' -o tsv`
AZURE_CONTAINER_REGISTRY_ENDPOINT=`az acr show -n $AZURE_CONTAINER_REGISTRY_NAME --query loginServer -o tsv`
TAG=`az acr repository show-tags -n $AZURE_CONTAINER_REGISTRY_NAME --repository $APP --top 1 --orderby time_desc -o tsv`
IMAGE_NAME=$AZURE_CONTAINER_REGISTRY_ENDPOINT/$APP:$TAG

# ---- set connection strings as secrets

kubectl delete secret servicebus-secret --ignore-not-found
kubectl create secret generic servicebus-secret --from-literal=connectionString=$SERVICEBUS_CONNECTION
kubectl delete secret storage-secret --ignore-not-found
kubectl create secret generic storage-secret --from-literal=accountName=$STORAGE_NAME \
    --from-literal=accountKey=$STORAGE_ACCOUNT_KEY

kubectl apply -f ./dapr-components.yml

if [[ "$STACK" =~ "-kn-" ]]; then
  SVC_SUFFIX=.default.svc.cluster.local
  cat $WORKLOAD | \
  yq eval ".|=select(.metadata.name==\"distributor\")
      .spec.template.spec.containers[0].image = \"$IMAGE_NAME\""  | \
  yq eval ".|=select(.metadata.name==\"receiver-express\")
      .spec.template.spec.containers[0].image = \"$IMAGE_NAME\""  | \
  yq eval ".|=select(.metadata.name==\"receiver-standard\")
      .spec.template.spec.containers[0].image = \"$IMAGE_NAME\""  | \
  kubectl apply -f -
else
  SVC_SUFFIX=-svc
  cat $WORKLOAD | \
  yq eval ".spec|=select(.selector.matchLabels.app==\"distributor\")
      .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
  yq eval ".spec|=select(.selector.matchLabels.app==\"receiver-express\") 
      .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
  yq eval ".spec|=select(.selector.matchLabels.app==\"receiver-standard\")
      .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
  kubectl apply -f -
fi

DAPR_VERSION=$(helm get metadata dapr -n dapr-system -o yaml | yq -r .appVersion)

if [[ $PATTERN =~ 'shared' ]]; then

  apps=("distributor" "receiver-express" "receiver-standard")

  for app in "${apps[@]}"
  do
    echo "$app"

    helm upgrade --install $app-dapr oci://registry-1.docker.io/daprio/dapr-shared-chart \
      --set fullnameOverride=$app-dapr \
      --set shared.strategy=deployment \
      --set shared.scheduling.nodeSelector.agentpool=classic \
      --set shared.deployment.replicas=1 \
      --set shared.daprd.image.tag=$DAPR_VERSION \
      --set shared.appId=$app \
      --set shared.daprd.config=appconfig \
      --set shared.remoteURL=$app$SVC_SUFFIX \
      --set shared.remotePort=80 \
      --set shared.controlPlane.placementServerAddress="''" \
      --set shared.daprd.listenAddresses=0.0.0.0 \
      --set shared.daprd.appHealth.enabled=true \
      --set shared.daprd.appHealth.probeTimeout=1000

  done
fi
