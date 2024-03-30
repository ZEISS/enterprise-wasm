#!/bin/bash

cargo build --target wasm32-wasi --release
wasmedge compile target/wasm32-wasi/release/warpwasi_dapr_rs.wasm target/warpwasi_dapr_rs.wasm

did=`docker run -d --name azurerite -p 10000:10000 -p 10001:10001 -p 10002:10002 \
   -e AZURITE_ACCOUNTS="azurerite:bm9rZXkK" \
   mcr.microsoft.com/azure-storage/azurite`
echo "azureite started in docker with ID $did"

[ -d .dapr ] && rm -rf .dapr

dapr run -f dapr-multi-run.yml &
pid=$!

trap "pgrep -P $pid | xargs kill && kill $pid && docker rm $did --force" INT HUP

wait $pid
