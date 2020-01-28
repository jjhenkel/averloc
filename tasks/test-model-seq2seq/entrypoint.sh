#!/bin/sh

set -ex

python /model/evaluate.py \
  --data_path /mnt/inputs/test.tsv \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
    $@

python /model/attack.py \
  --data_path /mnt/inputs/test.tsv \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
    $@

if [ -f /mnt/inputs/baseline.tsv ]; then
  cat /mnt/inputs/baseline.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /baseline-fixed.tsv
  
  python /model/evaluate.py \
    --data_path /baseline-fixed.tsv \
    --expt_dir /models/lstm \
    --output_dir /mnt/outputs \
    --load_checkpoint Best_F1 \
    $@
fi

