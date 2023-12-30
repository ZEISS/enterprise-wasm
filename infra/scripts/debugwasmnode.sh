#!/bin/bash
kubectl debug $(kubectl get node -l=agentpool=npspin -o name) -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
