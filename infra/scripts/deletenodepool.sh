#!/bin/bash

set -e

terraform output -raw kube_config > ~/.kube/config
RESOURCE_GROUP_NAME=`terraform output -json script_vars | jq -r .resource_group`
CLUSTER=`az aks list -g $RESOURCE_GROUP_NAME --query '[0].name' -o tsv`

NAME=${1-wasm}

if [[ ! -z "$NAME" ]]; then
  STATENAME=`terraform show -json | jq -r ".values.root_module.child_modules | . [] | select(.address==\"module.aks\") | .resources |. [] | select(.values.name==\"$NAME\") | .address"`

  echo $NAME $STATENAME
  if [[ ! -z "$STATENAME" ]]; then
    az aks nodepool delete --cluster-name $CLUSTER -g $RESOURCE_GROUP_NAME -n $NAME
    terraform state rm "$STATENAME"
  fi
fi



