#!/bin/bash

set -eoux pipefail
source ../../helpers/common.sh

WORKLOAD=./workload-kn.yml

kubectl delete -f $WORKLOAD
