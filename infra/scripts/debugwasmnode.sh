#!/bin/bash

# force debug pod on backend pool
wget -q -O- https://raw.githubusercontent.com/KWasm/kwasm-node-installer/main/example/debug.yaml | \
yq eval ".spec|=select(.selector.matchLabels.app==\"default\")
    .template.spec.nodeSelector.agentpool = \"wasm\"" | \
kubectl apply -f -

kubectl exec -it $(kubectl get pod -l=name=kwasm-debug -o name | awk 'FNR==1{print $1}') -- /bin/bash
