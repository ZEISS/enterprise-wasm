#!/bin/bash
kubectl apply -f https://raw.githubusercontent.com/KWasm/kwasm-node-installer/main/example/debug.yaml
kubectl exec -it $(kubectl get pod -l=name=kwasm-debug -o name) -- /bin/bash
