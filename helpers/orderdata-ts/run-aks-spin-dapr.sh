#!/bin/bash

set -e

npx tsc

REPO_ROOT=`git rev-parse --show-toplevel`
TARGET_INFRA_FOLDER=$REPO_ROOT/infra/aks-spin-dapr
RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`

SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
SERVICEBUS_CONNECTION=`az servicebus namespace authorization-rule keys list -g $RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE -n RootManageSharedAccessKey --query primaryConnectionString -o tsv`
STORAGE_NAME=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.Storage/storageAccounts --query '[0].name' -o tsv`
STORAGE_BLOB_CONNECTION=`az storage account show-connection-string -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME  --query connectionString -o tsv`
STORAGE_ACCOUNT_KEY=`az storage account keys list -g $RESOURCE_GROUP_NAME -n $STORAGE_NAME --query "[?permissions == 'FULL'] | [0].value" -o tsv `

# clear outbox blob folders
containers=(express-outbox standard-outbox)
for c in "${containers[@]}"
do
  az storage blob delete-batch --source $c \
    --account-name $STORAGE_NAME \
    --connection-string $STORAGE_BLOB_CONNECTION
done

# startup test-data app
APP_ID=test-data
APP_PORT=3001
DAPR_HTTP_PORT=3501

JSON_STRING=$( jq -n \
                  --arg sbc "$SERVICEBUS_CONNECTION" \
                  --arg stn "$STORAGE_NAME" \
                  --arg stk "$STORAGE_ACCOUNT_KEY" \
                  '{SERVICEBUS_CONNECTION: $sbc, STORAGE_NAME: $stn, STORAGE_ACCOUNT_KEY: $stk}' )
echo $JSON_STRING > ./.secrets.json

[ -d .dapr ] && rm -rf .dapr
dapr run --dapr-http-max-request-size 16 -f ./run-aks-spin-dapr.yml &
pid=$!

trap "pgrep -P $pid | xargs kill && kill $pid" INT HUP ERR

# ---- wait until app is healthy
until [ \
  "$(curl -s -w '%{http_code}' -o /dev/null "http://localhost:$APP_PORT/healthz")" \
  -eq 200 ]
do
  sleep 5
done

# ---- send test data
TARGET_COUNT=10000
DELAY=1

generate_post_data()
{
 jq -n \
      --arg tc "$TARGET_COUNT" \
      '{count: ($tc|tonumber)}'
}

generate_schedule_data()
{
 jq -n \
      --arg d "$DELAY" \
      '{scheduleDelayMinutes: ($d|tonumber)}'
}

if [ $(curl -s http://localhost:$APP_PORT/test-data) = "{}" ]; then
  echo "### generating test data ###"
  curl -s -d "$(generate_post_data)" http://localhost:$APP_PORT/test-data \
      -H 'Content-Type: application/json'
fi

echo "### initiating test ###"
PUSHRESPONSE=`curl -s -d "$(generate_schedule_data)" http://localhost:$APP_PORT/schedule-test \
    -H 'Content-Type: application/json'`
echo pr $PUSHRESPONSE
SCHEDULE=`echo $PUSHRESPONSE | jq -r '.scheduledTimestamp'`
echo s $SCHEDULE
echo wait ${DELAY}m for scheduled time
sleep $(( $DELAY * 60 ))

# ---- wait until all scheduled messages have been written to blob
ACTUAL_COUNT=0

until [ $ACTUAL_COUNT -eq $TARGET_COUNT ]
do
  ACTUAL_COUNT=0

  for c in "${containers[@]}"
  do
    blob_count=`az storage blob list -c $c --num-results $TARGET_COUNT \
      --account-name $STORAGE_NAME --connection-string $STORAGE_BLOB_CONNECTION --query "length(@)" -o tsv`

    ACTUAL_COUNT=$(($ACTUAL_COUNT+$blob_count))
  done

  echo $ACTUAL_COUNT of $TARGET_COUNT

  if [ $ACTUAL_COUNT -lt $TARGET_COUNT ]; then sleep 10; fi
done

# ---- detect when last blob has been written
LAST_WRITE=${SCHEDULE:0:19}

for c in "${containers[@]}"
do
  last=`az storage blob list -c $c --num-results $TARGET_COUNT \
    --account-name $STORAGE_NAME --connection-string $STORAGE_BLOB_CONNECTION --query "[].properties.lastModified | reverse(sort(@))[0]" -o tsv`
  last=${last:0:19}

  if [ "$last" \> "$LAST_WRITE" ]; then
    LAST_WRITE=$last
  fi
done

# ---- calculate timespan from schedule to blob last written
echo $SCHEDULE $LAST_WRITE
schedule_epoch=$(date -d $SCHEDULE +%s)
last_write_epoch=$(date -d $LAST_WRITE +%s)
runtime_seconds=$(( $last_write_epoch - $schedule_epoch ))

echo "$SCHEDULE | $TARGET_COUNT | $runtime_seconds"
echo "$SCHEDULE | $TARGET_COUNT | $runtime_seconds | $1" >> $REPO_ROOT/LOG.md


pgrep -P $pid | xargs kill && kill $pid
