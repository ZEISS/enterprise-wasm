#!/bin/bash

set -e

LOCAL_SERVICE_PORT=8080
LOCAL_DAPR_PORT=8081
POD_PORT=80

case "$1" in
  e)
    SERVICE=receiver-express-svc
    DAPR=receiver-express-dapr
    ;;
  s)
    SERVICE=receiver-standard-svc
    DAPR=receiver-standard-dapr
    ;;
  *)
    SERVICE=distributor-svc
    DAPR=distributor-dapr
    ;;
esac

# clean up the background port forward process on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

echo "starting port forward to $SERVICE"
kubectl port-forward "svc/$SERVICE" $LOCAL_SERVICE_PORT:$POD_PORT > /dev/null 2>&1 &
kubectl port-forward "svc/$DAPR" $LOCAL_DAPR_PORT:$POD_PORT > /dev/null 2>&1 &

echo "waiting for port forward to be ready"
timeout 5 sh -c 'until nc -z $0 $1; do sleep 1; done' '127.0.0.1' $LOCAL_SERVICE_PORT

echo "::: Spin health :::"
curl -v http://127.0.0.1:$LOCAL_SERVICE_PORT/.well-known/spin/health
echo -e "\r::: Dapr metadata direct :::"
curl -v http://127.0.0.1:$LOCAL_DAPR_PORT/v1.0/metadata
echo -e "\r::: Dapr metadata indirect from Spin service :::"
curl -v http://127.0.0.1:$LOCAL_SERVICE_PORT/dapr-metadata
echo -e "\r"

echo q-order-ingress Standard
curl -X POST http://127.0.0.1:$LOCAL_DAPR_PORT/v1.0/bindings/q-order-ingress \
  -H "Content-Type: application/json" \
  -d '{
        "data": {
          "OrderId": 1,
          "Delivery": "Standard"
        },
        "metadata": {
          "ttlInSeconds": "60"
        },
        "operation": "create"
      }'

echo q-order-ingress Express
curl -X POST http://127.0.0.1:$LOCAL_DAPR_PORT/v1.0/bindings/q-order-ingress \
  -H "Content-Type: application/json" \
  -d '{
        "data": {
          "OrderId": 2,
          "Delivery": "Express"
        },
        "metadata": {
          "ttlInSeconds": "60"
        },
        "operation": "create"
      }'
