#!/bin/sh

set -ex

python /model/evaluate.py \
  --data_path /mnt/inputs/test.tsv \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
  --output_fname results-test \
    $@

if [ -f /mnt/inputs/data.baseline.c2s ]; then
  python /model/evaluate.py \
    --data_path /mnt/inputs/baseline.tsv \
    --expt_dir /models/lstm \
    --output_dir /mnt/outputs \
    --load_checkpoint Best_F1 \
    --output_fname results-baseline \
    $@
fi

