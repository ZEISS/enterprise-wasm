#!/bin/bash

set -eoux pipefail
source ../../helpers/common.sh

WORKLOAD=./workload-svc.yml

kubectl delete -f $WORKLOAD
