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

if [ $SPIN_DEPLOY = 'operator' ]; then
  kubectl delete -f ./workload-aks-shared-operator.yml
else
  kubectl delete -f ./workload-aks-$PATTERN-deploy.yml
fi

kubectl delete secret servicebus-secret --ignore-not-found
kubectl delete secret storage-secret --ignore-not-found
kubectl delete -f ./dapr-components.yml

if [ $PATTERN == 'shared' ]; then

  helm uninstall receiver-standard-dapr receiver-express-dapr distributor-daprA

fi

