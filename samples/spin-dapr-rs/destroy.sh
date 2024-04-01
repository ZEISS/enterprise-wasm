#!/bin/bash

source ../../helpers/common.sh
get_deployment_configuration ${1:-shared}

kubectl delete -f $WORKLOAD

kubectl delete secret servicebus-secret --ignore-not-found
kubectl delete secret storage-secret --ignore-not-found
kubectl delete -f ./dapr-components.yml

if [ $PATTERN == 'shared' ]; then

  helm uninstall receiver-standard-dapr receiver-express-dapr distributor-dapr

fi
