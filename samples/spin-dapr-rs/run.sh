#!/bin/bash

set -e

[[ -d ".spin" ]] && rm -rf .spin

spin build

TARGET_INFRA_FOLDER=../../infra/aks-spin-dapr
RESOURCE_GROUP_NAME=`terraform output -state=$TARGET_INFRA_FOLDER/terraform.tfstate -json script_vars | jq -r .resource_group`

SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`

APP_ID=distributor
APP_PORT=3000
DAPR_HTTP_PORT=3500
export SPIN_VARIABLE_DAPR_URL=http://localhost:$DAPR_HTTP_PORT

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  '{SERVICEBUS_CONNECTION: $sbc}' )
echo $JSON_STRING > ./.secrets.json

dapr run --app-id ${APP_ID} \
    --app-port ${APP_PORT} \
    --dapr-http-port ${DAPR_HTTP_PORT} \
    --log-level warn \
    --enable-app-health-check \
    --app-health-probe-interval 60 \
    --app-health-check-path=/healthz \
    --resources-path ./components/ \
    --config ./components/config.yaml \
    -- spin up
