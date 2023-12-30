#!/bin/bash

set -e

curl -v http://localhost:3500/v1.0/metadata

curl -v http://localhost:3000/q-order-ingress \
  -H "Content-Type: application/json" \
  -d '{ "name": "Hi" }'

curl -v http://localhost:3500/v1.0/bindings/q-order-ingress \
  -H "Content-Type: application/json" \
  -d '{
        "data": {
          "name": "Hi"
        },
        "metadata": {
          "ttlInSeconds": "60"
        },
        "operation": "create"
      }'
