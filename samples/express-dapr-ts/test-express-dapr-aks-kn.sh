#!/bin/bash

set -e

LOCAL_SERVICE_PORT=8080
LOCAL_DAPR_PORT=8081
POD_SERVICE_PORT=80

case "$2" in
  ""|shared)
    POD_DAPR_PORT=3500
    DAPR_SERVICE_SUFFIX=dapr
    ;;
  sidecar)
    POD_DAPR_PORT=3500
    DAPR_SERVICE_SUFFIX=svc
    ;;
  *)
    echo "usage: test-express-dapr-aks.sh (e|s|d) (shared|sidecar)"
    exit 1
esac

case "$1" in
  ""|d)
    SERVICE=distributor
    DAPR=distributor-$DAPR_SERVICE_SUFFIX
    ;;
  e)
    SERVICE=receiver-express
    DAPR=receiver-express-$DAPR_SERVICE_SUFFIX
    ;;
  s)
    SERVICE=receiver-standard
    DAPR=receiver-standard-$DAPR_SERVICE_SUFFIX
    ;;
  *)
    echo "usage: test-spin-dapr-aks.sh (e|s|d) (shared|sidecar)"
    exit 1
esac

# clean up the background port forward process on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

echo "starting port forward to $SERVICE"
# kubectl port-forward "svc/$SERVICE" $LOCAL_SERVICE_PORT:$POD_SERVICE_PORT > /dev/null 2>&1 &
kubectl port-forward "svc/$DAPR" $LOCAL_DAPR_PORT:$POD_DAPR_PORT > /dev/null 2>&1 &

echo "waiting for port forward to be ready"
# timeout 15 sh -c 'until nc -z $0 $1; do sleep 1; done' '127.0.0.1' $LOCAL_SERVICE_PORT
timeout 15 sh -c 'until nc -z $0 $1; do sleep 1; done' '127.0.0.1' $LOCAL_DAPR_PORT

echo -e "\r::: Dapr metadata direct :::"
curl -v http://127.0.0.1:$LOCAL_DAPR_PORT/v1.0/metadata
echo -e "\r::: Dapr metadata indirect from service :::"
# curl -v http://127.0.0.1:$LOCAL_SERVICE_PORT/dapr-metadata
echo -e "\r"

# if [ "$SERVICE" = "distributor-svc" ]; then
  echo q-order-ingress Standard
  curl -X POST http://127.0.0.1:$LOCAL_DAPR_PORT/v1.0/bindings/q-order-ingress \
    -H "Content-Type: application/json" \
    -d '{
          "data": {
            "orderId": 1,
            "delivery": "Standard"
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
            "orderId": 2,
            "delivery": "Express"
          },
          "metadata": {
            "ttlInSeconds": "60"
          },
          "operation": "create"
        }'
# fi
