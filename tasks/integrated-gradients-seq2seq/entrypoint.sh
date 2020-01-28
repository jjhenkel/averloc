#!/bin/sh

set -ex

mkdir -p /mnt/outputs

python /model/evaluate.py \
  --data_path /mnt/inputs.tsv \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
  --save \
  --attributions \
  $@
