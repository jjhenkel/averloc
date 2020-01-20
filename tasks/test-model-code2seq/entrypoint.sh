#!/bin/bash

mkdir -p /models

set -ex

# python3 -u /code2seq/code2seq.py \
#   --data "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data" \
#   --test "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data.val.c2s" \
#   --save_prefix /models

python3 /code2seq/code2seq.py \
  --load /app/models/java-large-model/model_iter52.release \
  --test /mnt/inputs/data.test.c2s | tail -n3

if [ -f /mnt/inputs/data.baseline.c2s ]; then
  python3 /code2seq/code2seq.py \
    --load /app/models/java-large-model/model_iter52.release \
    --test /mnt/inputs/data.baseline.c2s | tail -n3
fi
