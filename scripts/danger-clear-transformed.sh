#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker run -it --rm \
  -v "${DIR}/../datasets/transformed/normalized:/mnt" \
  --entrypoint bash \
  debian:9 \
    -c 'rm -rf /mnt/c2s/* /mnt/csn/* /mnt/sri/*'
