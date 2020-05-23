#!/bin/bash

set -ex

mkdir -p /mnt/staging
mkdir -p /mnt/outputs/gradient-targeting
mkdir -p /mnt/outputs/random-targeting

echo "[Step 1/2] Preparing data..."

FLAGS="--distinct"
if [ "${NO_RANDOM}" != "true" ]; then
  FLAGS="--random --distinct"
fi

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    python3 /app/app.py train $@

    cat /mnt/inputs/transforms.Identity/valid.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/random-targeting/valid.tsv
    cp /mnt/outputs/random-targeting/valid.tsv /mnt/outputs/gradient-targeting/valid.tsv
fi


if [ "${NO_TEST}" != "true" ]; then
  python3 /app/app.py test $@
fi

echo "  + Done!"

echo "[Step 2/2] Doing taregting..."

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    time python3 /model/gradient_attack.py \
    --data_path /mnt/staging/train.tsv \
    --expt_dir /models/lstm \
    --load_checkpoint "${CHECKPOINT}" \
    --save_path /mnt/staging/targets-train.json \
    ${FLAGS}

    python3 /model/replace_tokens.py \
    --source_data_path /mnt/staging/train.tsv \
    --dest_data_path /mnt/outputs/gradient-targeting/train.tsv \
    --mapping_json /mnt/staging/targets-train-gradient.json

  if [ "${NO_RANDOM}" != "true" ]; then
    python3 /model/replace_tokens.py \
    --source_data_path /mnt/staging/train.tsv \
    --dest_data_path /mnt/outputs/random-targeting/train.tsv \
    --mapping_json /mnt/staging/targets-train-random.json
  fi
fi

if [ "${NO_TEST}" != "true" ]; then
  time python3 /model/gradient_attack.py \
    --data_path /mnt/staging/test.tsv \
    --expt_dir /models/lstm \
    --load_checkpoint "${CHECKPOINT}" \
    --save_path /mnt/staging/targets-test.json \
    ${FLAGS}

  python3 /model/replace_tokens.py \
    --source_data_path /mnt/staging/test.tsv \
    --dest_data_path /mnt/outputs/gradient-targeting/test.tsv \
    --mapping_json /mnt/staging/targets-test-gradient.json

  if [ "${NO_RANDOM}" != "true" ]; then
    python3 /model/replace_tokens.py \
      --source_data_path /mnt/staging/test.tsv \
      --dest_data_path /mnt/outputs/random-targeting/test.tsv \
      --mapping_json /mnt/staging/targets-test-random.json
  fi
fi

echo "  + Done!"
