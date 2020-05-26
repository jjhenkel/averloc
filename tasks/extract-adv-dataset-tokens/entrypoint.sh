#!/bin/bash

set -ex

echo "[Step 1/2] Preparing data..."

FLAGS="--distinct"
if [ "${NO_RANDOM}" != "true" ]; then
  FLAGS="--random --distinct"
  mkdir -p /mnt/outputs/random-targeting
  if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    cat /mnt/inputs/transforms.Identity/valid.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/random-targeting/valid.tsv
  fi
fi
if [ "${NO_GRADIENT}" != "true" ]; then
  mkdir -p /mnt/outputs/gradient-targeting
  if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    cat /mnt/inputs/transforms.Identity/valid.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/gradient-targeting/valid.tsv
  fi
else
  FLAGS="--no_gradient --distinct"
  if [ "${NO_RANDOM}" != "true" ]; then
    FLAGS="--random --no_gradient --distinct"
  fi
fi

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    python3 /app/app.py train $@
fi

if [ "${NO_TEST}" != "true" ]; then
  python3 /app/app.py test $@
fi

echo "  + Done!"

echo "[Step 2/2] Doing taregting..."

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    time python3 /model/gradient_attack.py \
    --data_path /mnt/outputs/train.tsv \
    --expt_dir /models/lstm \
    --load_checkpoint "${CHECKPOINT}" \
    --save_path /mnt/outputs/targets-train.json \
    ${FLAGS}

  if [ "${NO_GRADIENT}" != "true" ]; then
    python3 /model/replace_tokens.py \
    --source_data_path /mnt/outputs/train.tsv \
    --dest_data_path /mnt/outputs/gradient-targeting/train.tsv \
    --mapping_json /mnt/outputs/targets-train-gradient.json
  fi

  if [ "${NO_RANDOM}" != "true" ]; then
    python3 /model/replace_tokens.py \
    --source_data_path /mnt/outputs/train.tsv \
    --dest_data_path /mnt/outputs/random-targeting/train.tsv \
    --mapping_json /mnt/outputs/targets-train-random.json
  fi
fi

if [ "${NO_TEST}" != "true" ]; then
  time python3 /model/gradient_attack.py \
    --data_path /mnt/outputs/test.tsv \
    --expt_dir /models/lstm \
    --load_checkpoint "${CHECKPOINT}" \
    --save_path /mnt/outputs/targets-test.json \
    ${FLAGS}

  if [ "${NO_GRADIENT}" != "true" ]; then
    python3 /model/replace_tokens.py \
      --source_data_path /mnt/outputs/test.tsv \
      --dest_data_path /mnt/outputs/gradient-targeting/test.tsv \
      --mapping_json /mnt/outputs/targets-test-gradient.json
  fi

  if [ "${NO_RANDOM}" != "true" ]; then
    python3 /model/replace_tokens.py \
      --source_data_path /mnt/outputs/test.tsv \
      --dest_data_path /mnt/outputs/random-targeting/test.tsv \
      --mapping_json /mnt/outputs/targets-test-random.json
  fi
fi

rm -f /mnt/outputs/test.tsv
rm -f /mnt/outputs/train.tsv
rm -f /mnt/outputs/targets-test-random.json
rm -f /mnt/outputs/targets-test-gradient.json
rm -f /mnt/outputs/targets-train-random.json
rm -f /mnt/outputs/targets-train-gradient.json

echo "  + Done!"
