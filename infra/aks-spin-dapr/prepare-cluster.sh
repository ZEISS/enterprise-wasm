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

# CLUSTER_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ContainerService/managedClusters --query '[0].name' -o tsv`

# az aks update -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --kube-proxy-config kube-proxy.json

az acr login -n $AZURE_CONTAINER_REGISTRY_NAME

# configure the directory where spin-operator is cloned
SPIN_OPERATOR_HOME="${SPIN_OPERATOR_HOME:-$HOME/src/spin-operator}"

# configure the image name for the operator
OPERATOR_REP="${AZURE_CONTAINER_REGISTRY_ENDPOINT}/spin-operator"
OPERATOR_IMG="${OPERATOR_REP}:latest"

# ensure the runtimeclass is applied
kubectl apply -f runtimeclass.yaml

# deploy cert-manager as a dependency for the spin-operator if validating webhook is enabled
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.yaml

pushd "$SPIN_OPERATOR_HOME"
# build and publish the operator's image to ACR
# see: https://github.com/spinkube/spin-operator/blob/main/documentation/content/quickstart.md#set-up-your-kubernetes-cluster
# NOTE: this target uses docker buildx for multi-platform images
make docker-build-and-publish-all IMG=$OPERATOR_IMG

# install the spin-operator's CRDs
make install

# actually deploy the spin-operator
# see: https://github.com/spinkube/spin-operator/blob/main/documentation/content/quickstart.md#deploy-the-spin-operator
make deploy IMG=$OPERATOR_IMG

popd

# install the SpinAppExecutor
kubectl apply -f spin-executor-shim.yaml


#
# pushd ../../../spin-operator/
# OPERATOR_REP=$AZURE_CONTAINER_REGISTRY_ENDPOINT/spin-operator
# OPERATOR_IMG=$OPERATOR_REP:latest
# # make docker-build docker-push IMG=$OPERATOR_IMG
# make install
#
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.yaml
#
# # kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
# # make deploy IMG=$OPERATOR_IMG
#
# kubectl apply -f spin-runtime-class.yaml
# helm upgrade --install spin-operator \
#   --namespace spin-operator \
#   --create-namespace \
#   --devel \
#   --wait \
#   --set controllerManager.manager.image.repository=$OPERATOR_REP \
#   --set certmanager.enabled=false \
#   --set certmanager.installCRDs=false \
#   ./charts/spin-operator
#   # oci://ghcr.io/spinkube/spin-operator
#
# popd
