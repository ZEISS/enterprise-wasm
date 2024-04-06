#!/bin/bash
#
source ./common.sh

SERVICEBUS_NAMESPACE=`az resource list -g $RESOURCE_GROUP_NAME --resource-type Microsoft.ServiceBus/namespaces --query '[0].name' -o tsv`
SERVICEBUS_ENDPOINT=`az servicebus namespace show -n $SERVICEBUS_NAMESPACE -g $RESOURCE_GROUP_NAME --query "serviceBusEndpoint" -o tsv`
EXPIRY=$((60 * 24)) # Default token expiry is 1 hour

queues=("ingress" "express" "standard")
suffixes=("" "/\$deadletterqueue")

for queue in "${queues[@]}"
do
  for suffix in "${suffixes[@]}"
  do
    QUEUE_NAME="q-order-$queue$suffix"
    echo $QUEUE_NAME
    SERVICE_BUS_QUEUE_URL="$SERVICEBUS_ENDPOINT$QUEUE_NAME/messages/head"
    SHARED_ACCESS_KEY_NAME=RootManageSharedAccessKey
    SHARED_ACCESS_KEY=$(az servicebus namespace authorization-rule keys list \
      --resource-group ${RESOURCE_GROUP_NAME} \
      --namespace-name ${SERVICEBUS_NAMESPACE} \
      --name $SHARED_ACCESS_KEY_NAME \
      --query primaryKey \
      --output tsv)

    ENCODED_URI=$(echo -n $SERVICE_BUS_QUEUE_URL | jq -s -R -r @uri)
    TTL=$(($(date +%s) + $EXPIRY))
    UTF8_SIGNATURE=$(printf "%s\n%s" $ENCODED_URI $TTL | iconv -t utf8)
    HASH=$(echo -n "$UTF8_SIGNATURE" | openssl sha256 -hmac $SHARED_ACCESS_KEY -binary | base64)
    ENCODED_HASH=$(echo -n $HASH | jq -s -R -r @uri)
    SAS_TOKEN=$(echo -n "SharedAccessSignature sr=$ENCODED_URI&sig=$ENCODED_HASH&se=$TTL&skn=$SHARED_ACCESS_KEY_NAME")

    until [ \
      "$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$SERVICE_BUS_QUEUE_URL" \
      --header "Authorization: $SAS_TOKEN" \
      --header 'Content-Type: application/json' \
      -d '')" \
      -ne 200 ]
        do
          printf '.'
        done
        echo -e "\r"
      done
    done

