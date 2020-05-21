#!/bin/sh

set -ex

mkdir -p /mnt/outputs
mkdir -p /staging

TRAIN_FILE=/mnt/inputs/train.tsv
VALID_FILE=/mnt/inputs/valid.tsv

if grep -qF 'from_file' "${TRAIN_FILE}"; then
  echo "Stripping first column hashes..."
  cat "${TRAIN_FILE}" | cut -f2- > /train.tsv
  cat "${VALID_FILE}" | cut -f2- > /valid.tsv
  TRAIN_FILE=/train.tsv
  VALID_FILE=/valid.tsv
fi

if [ "${1}" = "--regular_training" ]; then
  shift
  python /model/train.py \
    --train_path "${TRAIN_FILE}" \
    --dev_path "${VALID_FILE}" \
    --expt_name lstm \
    --expt_dir /mnt/outputs $@
elif [ "${1}" = "--augmented_training" ]; then
  shift
  TRAIN_FILE=/staging/train.tsv
  python /app/augment.py
  python /model/train.py \
    --train_path "${TRAIN_FILE}" \
    --dev_path "${VALID_FILE}" \
    --expt_name lstm \
    --expt_dir /mnt/outputs $@
else
  python /model/train_adv.py \
    --train_path "${TRAIN_FILE}" \
    --dev_path "${VALID_FILE}" \
    --expt_name lstm \
    --expt_dir /mnt/outputs $@
fi

# python train.py --train_path data/java-small/transforms.Identity/train.tsv --dev_path data/java-small/transforms.Identity/valid.tsv --expt_name java_small_identity  --resume --expt_dir experiment/java_small_identity --load_checkpoint Best_F1
