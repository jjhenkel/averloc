#!/bin/bash

mkdir -p /mnt/outputs/models

set -ex

python3 -u /code2seq/code2seq.py \
  --data "/mnt/inputs/data" \
  --test "/mnt/inputs/data.val.c2s" \
  -td "/mnt/inputs" \
  -t 7 \
  --save_prefix /mnt/outputs/models
