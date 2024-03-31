#!/bin/bash

# define common variables for deployment patterns and runtime

set -e

REPO_ROOT=`git rev-parse --show-toplevel`
source <(cat $REPO_ROOT/.env)
RUNTIME=`echo $STACK | awk -F'-' '{print $1 "-" $2}'`
TARGET_INFRA_FOLDER=$REPO_ROOT/$INFRA_FOLDER

RESOURCE_GROUP_NAME=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .resource_group`
SPIN_DEPLOY=`terraform -chdir=$TARGET_INFRA_FOLDER output -json script_vars | jq -r .spin_deploy`

function get_deployment_configuration {
  case "${1:-shared}" in
    shared)
      if [ $SPIN_DEPLOY = 'operator' ]; then
        PATTERN=shared-operator
      else
        PATTERN=shared-deploy
      fi
      ;;
    sidecar)
      if [ $SPIN_DEPLOY = 'operator' ]; then
        echo "sidecar deployment not allowed with Spin operator deployment"
        exit 1
      else
        PATTERN=sidecar-deploy
      fi
      ;;
    *)
      echo "only shared or sidecar"
      exit 1
  esac
  WORKLOAD="./workload-$RUNTIME-$PATTERN.yml"
}
