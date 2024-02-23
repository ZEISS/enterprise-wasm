#!/bin/bash

set -e

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

# ensure the runtimeclass is applied
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

  helm upgrade --install spin-operator \
    --namespace spin-operator \
    --create-namespace \
    --devel \
    --wait \
    oci://ghcr.io/spinkube/spin-operator

  # az acr login -n $AZURE_CONTAINER_REGISTRY_NAME
  #
  # # configure the directory where spin-operator is cloned
  # SPIN_OPERATOR_HOME="${SPIN_OPERATOR_HOME:-$HOME/src/spin-operator}"
  #
  # # configure the image name for the operator
  # OPERATOR_REP="${AZURE_CONTAINER_REGISTRY_ENDPOINT}/spin-operator"
  # OPERATOR_IMG="${OPERATOR_REP}:latest"
  #
  # # deploy cert-manager as a dependency for the spin-operator if validating webhook is enabled
  # kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.yaml
  #
  # pushd "$SPIN_OPERATOR_HOME"
  # build and publish the operator's image to ACR
  # see: https://github.com/spinkube/spin-operator/blob/main/documentation/content/quickstart.md#set-up-your-kubernetes-cluster
  # NOTE: this target uses docker buildx for multi-platform images
  # make docker-build-and-publish-all IMG=$OPERATOR_IMG
  # docker push $OPERATOR_IMG
  #
  # # install the spin-operator's CRDs
  # make install

  # # actually deploy the spin-operator
  # # see: https://github.com/spinkube/spin-operator/blob/main/documentation/content/quickstart.md#deploy-the-spin-operator
  # # OPERATOR_IMG=rg.fr-par.scw.cloud/dlancashire-public/spin-operator-dev
  # make deploy IMG=$OPERATOR_IMG
  #
  # popd
  #
  # helm upgrade --install spin-operator \
  # --namespace spin-operator \
  # --create-namespace \
  # --set controllerManager.manager.image.repository=$OPERATOR_REP \
  # --devel \
  # --wait \
  # ../../../spin-operator/charts/spin-operator/
  # # oci://ghcr.io/spinkube/spin-operator
  # #
  # kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.1.0/spin-operator.crds.yaml
  # kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.1.0/spin-operator.runtime-class.yaml
  #
  # # install the SpinAppExecutor
  # kubectl rollout status deployment spin-operator-controller-manager -n spin-operator --timeout 90s
  # kubectl apply -f spin-executor-shim.yaml
fi
