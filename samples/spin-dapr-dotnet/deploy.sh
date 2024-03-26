#!/bin/bash

set -e

# ---- init

REPO_ROOT=`git rev-parse --show-toplevel`
TARGET_INFRA_FOLDER=../../infra/aks-spin-dapr
RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`
SPIN_DEPLOY=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .spin_deploy`

case "$1" in
  ""|shared)
    PATTERN=shared
    ;;
  sidecar)
    if [ $SPIN_DEPLOY = 'operator' ]; then
      echo "sidecar deployment not allowed with Spin operator deployment"
      exit 1
    fi
    PATTERN=sidecar
    ;;
  *)
    echo "usage: deploy.sh (shared|sidecar)"
    exit 1
esac

APP=spin-dapr-dotnet
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

if [ $SPIN_DEPLOY = 'operator' ]; then
  cat ./workload-aks-shared-operator.yml | \
  yq eval ".|=select(.metadata.name==\"distributor\")
      .spec.image = \"$IMAGE_NAME\"" | \
  yq eval ".|=select(.metadata.name==\"receiver-express\")
      .spec.image = \"$IMAGE_NAME\"" | \
  yq eval ".|=select(.metadata.name==\"receiver-standard\")
      .spec.image = \"$IMAGE_NAME\"" | \
  kubectl apply -f -
else
  cat ./workload-aks-$PATTERN-deploy.yml | \
  yq eval ".spec|=select(.selector.matchLabels.app==\"distributor\")
      .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
  yq eval ".spec|=select(.selector.matchLabels.app==\"receiver-express\")
      .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
  yq eval ".spec|=select(.selector.matchLabels.app==\"receiver-standard\")
      .template.spec.containers[0].image = \"$IMAGE_NAME\"" | \
  kubectl apply -f -
fi

DAPR_VERSION=$(helm get metadata dapr -n dapr-system -o yaml | yq -r .appVersion)

if [ $PATTERN = 'shared' ]; then

  apps=("distributor" "receiver-express" "receiver-standard")

  for app in "${apps[@]}"
  do
    echo "$app"

    # by default the Spin operator deploys a service without the '-svc' suffix
    if [ $SPIN_DEPLOY = 'operator' ]; then
      remoteUrl="$app"
    else
      remoteUrl="$app-svc"
    fi

    helm upgrade --install $app-dapr oci://registry-1.docker.io/daprio/dapr-shared-chart \
      --set fullnameOverride=$app-dapr \
      --set shared.strategy=deployment \
      --set shared.scheduling.nodeSelector.agentpool=default \
      --set shared.deployment.replicas=0 \
      --set shared.daprd.image.tag=$DAPR_VERSION \
      --set shared.appId=$app \
      --set shared.daprd.appHealth.enabled=true \
      --set shared.daprd.config=appconfig \
      --set shared.remoteURL=$remoteUrl \
      --set shared.remotePort=80 \
      --set shared.controlPlane.placementServerAddress="''" \
      --set shared.daprd.listenAddresses=0.0.0.0

  done
fi
