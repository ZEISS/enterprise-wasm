#!/bin/bash

case "$1" in
  ""|shared)
    PATTERN=shared
    ;;
  sidecar)
    PATTERN=sidecar
    ;;
  *)
    echo "usage: deploy.sh (shared|sidecar)"
    exit 1
esac

# ---- init

REPO_ROOT=`git rev-parse --show-toplevel`
source <(cat $REPO_ROOT/.env)
RUNTIME=`echo $STACK | awk -F'-' '{print $1 "-" $2}'`
TARGET_INFRA_FOLDER=$REPO_ROOT/$INFRA_FOLDER

RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`

kubectl delete -f ./workload-$RUNTIME-$PATTERN.yml
kubectl delete secret servicebus-secret --ignore-not-found
kubectl delete secret storage-secret --ignore-not-found
kubectl delete -f ./dapr-components.yml

helm uninstall receiver-standard-dapr receiver-express-dapr distributor-dapr
