#!/bin/sh

set -ex

TEST_FILE=/mnt/inputs/test.tsv

if grep -qF 'from_file' "${TEST_FILE}"; then
  echo "Stripping first column hashes..."
  cat "${TEST_FILE}" | cut -f2- > /inputs.tsv
  TEST_FILE=/inputs.tsv
fi

python /model/evaluate.py \
  --data_path "${TEST_FILE}" \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
    $@

python /model/attack.py \
  --data_path "${TEST_FILE}" \
  --expt_dir /models/lstm \
  --output_dir /mnt/outputs \
  --load_checkpoint Best_F1 \
    $@

if [ -f /mnt/inputs/baseline.tsv ]; then
  cat /mnt/inputs/baseline.tsv | cut -f2- > /baseline-fixed.tsv
  
  python /model/evaluate.py \
    --data_path /baseline-fixed.tsv \
    --expt_dir /models/lstm \
    --output_dir /mnt/outputs \
    --load_checkpoint Best_F1 \
    $@
fi

