#!/bin/bash

set -e

[[ -d ".spin" ]] && rm -rf .spin

spin build

TARGET_INFRA_FOLDER=../../infra/aks-spin-dapr
RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`

SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
STORAGE_ACCOUNT_KEY=`az storage account keys list -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME --query "[?permissions == 'FULL'] | [0].value" -o tsv `

APP_ID=distributor
APP_PORT=3001
DAPR_HTTP_PORT=3501
export SPIN_VARIABLE_DAPR_URL=http://localhost:$DAPR_HTTP_PORT

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stn "$STORAGE_NAME" \
                  --arg stk "$STORAGE_ACCOUNT_KEY" \
                  '{SERVICEBUS_CONNECTION: $sbc, STORAGE_NAME: $stn, STORAGE_ACCOUNT_KEY: $stk}' )
echo $JSON_STRING > ./.secrets.json

dapr run --app-id ${APP_ID} \
    --app-port ${APP_PORT} \
    --dapr-http-port ${DAPR_HTTP_PORT} \
    --log-level warn \
    --enable-app-health-check \
    --app-health-probe-interval 60 \
    --app-health-check-path=/healthz \
    --resources-path ./components-merged/ \
    --config ./components-merged/config.yaml \
    -- spin up --listen localhost:$APP_PORT
