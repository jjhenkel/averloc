#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker run -it --rm \
  -v "${DIR}/../datasets/preprocessed/ast-paths/_staging:/mnt" \
  --entrypoint bash \
  debian:9 \
    -c 'rm -rf /mnt/c2s/* /mnt/csn/*'
