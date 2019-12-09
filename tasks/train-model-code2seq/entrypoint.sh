#!/bin/bash

mkdir -p /models

set -ex

python3 -u /code2seq/code2seq.py \
  --data "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data" \
  --test "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data.val.c2s" \
  --save_prefix /models
