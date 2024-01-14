#!/bin/bash

did=`docker run -d --name azurerite -p 10000:10000 -p 10001:10001 -p 10002:10002 \
   -e AZURITE_ACCOUNTS="azurerite:bm9rZXkK" \
   mcr.microsoft.com/azure-storage/azurite`
echo "azureite started in docker with ID $did"

trap "docker rm $did --force" INT HUP

[ -d .spin ] && rm -rf .spin

npx tsc
dapr run --app-id=test-data --dapr-http-port=3500 --app-port=3000 --resources-path ./local-components/ -- node dist/app.js 
