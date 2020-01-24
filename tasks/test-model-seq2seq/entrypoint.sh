#!/bin/sh

set -ex

cat /mnt/inputs/test.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /test-fixed.tsv

python /model/evaluate.py \
  --data_path /test-fixed.tsv \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
  --output_fname results-test \
    $@

if [ -f /mnt/inputs/baseline.tsv ]; then
  cat /mnt/inputs/baseline.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /baseline-fixed.tsv
  
  python /model/evaluate.py \
    --data_path /baseline-fixed.tsv \
    --expt_dir /models/lstm \
    --output_dir /mnt/outputs \
    --load_checkpoint Best_F1 \
    --output_fname results-baseline \
    $@
fi

