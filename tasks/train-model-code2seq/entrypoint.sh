#!/bin/bash

mkdir -p /models

set -ex

<<<<<<< HEAD
# python3 -u /code2seq/code2seq.py \
#   --data "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data" \
#   --test "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data.val.c2s" \
#   --save_prefix /models

python3 /code2seq/code2seq.py \
  --load /app/models/java-large-model/model_iter52.release \
  --test /mnt/inputs/data.test.c2s
=======
python3 -u /code2seq/code2seq.py \
  --data "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data" \
  --test "/datasets/preprocessed/ast-paths/${DATASET_NAME}/data.val.c2s" \
  --save_prefix /models
>>>>>>> 456449a5524071af4774e6f0817a0650f3d7bc08
