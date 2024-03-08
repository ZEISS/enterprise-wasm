#!/bin/bash

set -e

CYCLES=${1:-10}

apps=($(for d in ./samples/*dapr-ts ; do echo ${d##*/}; done))

for app in "${apps[@]}"
do
  echo "build $app"

  pushd ./samples/$app
  ./build.sh
  popd
done

for app in "${apps[@]}"
do
  echo "deploy and test $app"

  pushd ./samples/$app
  ./deploy.sh shared
  popd

  pushd ./helpers/orderdata-ts
  for i in $(seq 1 $CYCLES);
  do
    ./run-aks-spin-dapr.sh $app
  done
  popd

  pushd ./samples/$app
  ./destroy.sh shared
  popd
done
