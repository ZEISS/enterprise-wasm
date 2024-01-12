#!/bin/bash

set -e

terraform output -raw kube_config > ~/.kube/config

# ---- install Wasm Shims
wget -q -O- https://raw.githubusercontent.com/KWasm/kwasm-node-installer/main/example/daemonset.yaml | \
yq eval ".spec|=select(.selector.matchLabels.app==\"default-init\")
    .template.spec.nodeSelector.agentpool = \"backend\"" | \
kubectl apply -f -

kubectl apply -f ./runtimeclass.yaml
kubectl apply -f ./namespaces.yaml
