#!/bin/bash

set -eoux pipefail

../scripts/deletenodepool.sh wasm
../scripts/deletenodepool.sh classic
