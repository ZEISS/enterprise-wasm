#!/bin/bash
NODE=${1:-1}p
NODENAME=`kubectl get node -l=agentpool=wasm -o name | sed -n $NODE`

echo will now debug into $NODENAME
echo "chroot /host"
echo "ctr --namespace k8s.io image ls | grep runwasi"

kubectl debug $NODENAME -it --image=mcr.microsoft.com/cbl-mariner/busybox:2.0

