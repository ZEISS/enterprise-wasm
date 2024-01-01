#!/bin/bash

docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 \
   -e AZURITE_ACCOUNTS="azurerite:bm9rZXkK" \
   mcr.microsoft.com/azure-storage/azurite
