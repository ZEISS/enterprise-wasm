#!/bin/bash

set -eoux pipefail

terraform output -raw kube_config > ~/.kube/config
RESOURCE_GROUP_NAME=`terraform output -json script_vars | jq -r .resource_group`
SPIN_DEPLOY=`terraform output -json script_vars | jq -r .spin_deploy`

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

kubectl apply -f runtimeclass.yaml

# deploy all components for spin-operator
if [ $SPIN_DEPLOY = 'operator' ]; then

  helm repo add jetstack https://charts.jetstack.io
  
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.13.3 \
    --set installCRDs=true \
    --wait

  # SPIN_OPERATOR_VERSION="20240308-213250-gdea45ba"
  #
  # # get the full commit sha from the chart's version
  # SPIN_OPERATOR_COMMIT=$(git ls-remote --refs ssh://git@github.com/spinkube/spin-operator.git | grep "${SPIN_OPERATOR_VERSION:(-7)}" | awk '{ print $1 }')
  #
  # echo "Applying spin-operator CRDs from ${SPIN_OPERATOR_COMMIT}"
  # kubectl kustomize "ssh://git@github.com/spinkube/spin-operator/config/crd?ref=${SPIN_OPERATOR_COMMIT}" | kubectl apply -f -
  #
  # helm upgrade --install \
  #   -n spin-operator \
  #   --create-namespace \
  #   --version "$SPIN_OPERATOR_VERSION" \
  #   --skip-crds \
  #   --set kwasm-operator.enabled=false \
  #   --wait \
  #   spin-operator oci://ghcr.io/spinkube/charts/spin-operator
  #
  # wget "https://github.com/spinkube/spin-operator/releases/download/v$SPIN_OPERATOR_VERSION/spin-operator.runtime-class.yaml" -O - -o /dev/null | \
  #   yq eval ".scheduling.nodeSelector.agentpool = \"wasm\"" | \
  #   kubectl apply -f -
  #
  # wget "https://raw.githubusercontent.com/spinkube/spin-operator/v$SPIN_OPERATOR_VERSION/config/samples/spin-shim-executor.yaml" -O - -o /dev/null | \
  #   kubectl apply -f -
  #   spin-operator oci://ghcr.io/spinkube/spin-operator

  SPIN_OPERATOR_VERSION="0.0.2"

  kubectl apply -f "https://github.com/spinkube/spin-operator/releases/download/v$SPIN_OPERATOR_VERSION/spin-operator.crds.yaml"

  helm upgrade --install \
    -n spin-operator \
    --create-namespace \
    --version "$SPIN_OPERATOR_VERSION" \
    --skip-crds \
    --set kwasm-operator.enabled=false \
    --wait \
    spin-operator oci://ghcr.io/spinkube/charts/spin-operator

  wget "https://github.com/spinkube/spin-operator/releases/download/v$SPIN_OPERATOR_VERSION/spin-operator.runtime-class.yaml" -O - -o /dev/null | \
    yq eval ".scheduling.nodeSelector.agentpool = \"wasm\"" | \
    kubectl apply -f -

  wget "https://raw.githubusercontent.com/spinkube/spin-operator/v$SPIN_OPERATOR_VERSION/config/samples/spin-shim-executor.yaml" -O - -o /dev/null | \
    kubectl apply -f -

fi
