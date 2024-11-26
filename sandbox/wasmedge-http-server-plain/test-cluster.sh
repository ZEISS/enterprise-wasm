#!/bin/bash

set -eoux pipefail

LOCAL_SERVICE_PORT=8080
POD_SERVICE_PORT=80
SVC_SUFFIX="-svc"
SERVICE=http-server$SVC_SUFFIX

# clean up the background port forward process on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

echo "starting port forward to $SERVICE"
kubectl port-forward svc/$SERVICE $LOCAL_SERVICE_PORT:$POD_SERVICE_PORT > /dev/null 2>&1 &

echo "waiting for port forward to be ready"
timeout 15 sh -c 'until nc -z $0 $1; do sleep 1; done' '127.0.0.1' $LOCAL_SERVICE_PORT

curl -v http://127.0.0.1:$LOCAL_SERVICE_PORT -d 'TEST'
