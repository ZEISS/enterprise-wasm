#!/bin/bash

set -e

usage="  USAGE: ./$(basename $0) [-h] [-d DELAY] [-c COUNT]

  Execute the orderdata-ts helper dapr app locally with processing done in AKS using Azure ServiceBus

  OPTIONS:
    -h            show this help text
    -c <CYCLES>   number of cycles
    -s <SUFFIX>   case suffix rs or ts (default : ts)
    
  EXAMPLE: run 5 cycles
    ./$(basename $0) -d 5"

CYCLES=10
SUFFIX=ts

while getopts ":hc:s:" option; do
   case $option in
      h)
        echo "${usage}"
        exit
        ;;
      c)
        CYCLES=$OPTARG
        ;;
      s)
        SUFFIX=$OPTARG
        ;;
   esac
done

apps=($(for d in ./samples/*dapr-$SUFFIX ; do echo ${d##*/}; done))

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
    ./run-cluster.sh $app
  done
  popd

  pushd ./samples/$app
  ./destroy.sh shared
  popd
done
