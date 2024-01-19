#!/bin/bash

set -e

# curl -v http://localhost:3500/v1.0/metadata

curl -v http://localhost:3001/dapr-metadata

curl -v http://localhost:3501/v1.0/bindings/q-order-ingress \
  -H "Content-Type: application/json" \
  -d '{
        "data": {
          "orderId": 1,
          "delivery": "Express"
        },
        "metadata": {
          "ttlInSeconds": "60"
        },
        "operation": "create"
      }'

curl -v http://localhost:3501/v1.0/bindings/q-order-ingress \
  -H "Content-Type: application/json" \
  -d '{
        "data": {
          "orderId": 2,
          "delivery": "Standard"
        },
        "metadata": {
          "ttlInSeconds": "60"
        },
        "operation": "create"
      }'
curl -v http://localhost:3004/test-data \
  -H 'Content-Type: application/json' \
  -d '{"count":5}' 
