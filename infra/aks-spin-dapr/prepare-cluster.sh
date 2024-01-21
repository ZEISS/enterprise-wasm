#!/bin/bash

set -e

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
APPINSIGHTS_ID=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Insights/components --query '[0].id' -o tsv` 
INSTRUMENTATION_KEY=`az monitor app-insights component show --ids $APPINSIGHTS_ID --query instrumentationKey -o tsv`

# ---- install OpenTelemetry
cat ./open-telemetry-collector-appinsights.yaml | \
sed "s/<INSTRUMENTATION-KEY>/$INSTRUMENTATION_KEY/" | \
yq eval '. | select(.kind=="Deployment").spec.template.spec.nodeSelector={"agentpool":"default"}' | \
kubectl apply -f -
kubectl apply -f ./collector-config.yaml
