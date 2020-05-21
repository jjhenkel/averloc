#!/bin/bash

set -ex

mkdir -p /mnt/staging
mkdir -p /mnt/outputs/gradient-targeting
mkdir -p /mnt/outputs/random-targeting

echo "[Step 1/2] Preparing data..."

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    python3 /app/app.py train $@

    cat /mnt/inputs/transforms.Identity/valid.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/random-targeting/valid.tsv
    cp /mnt/outputs/random-targeting/valid.tsv /mnt/outputs/gradient-targeting/valid.tsv
fi

python3 /app/app.py test $@

echo "  + Done!"

echo "[Step 2/2] Doing taregting..."

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
    time python3 /model/gradient_attack.py \
    --data_path /mnt/staging/train.tsv \
    --expt_dir /models/lstm \
    --load_checkpoint Best_F1 \
    --random --distinct \
    --save_path /mnt/staging/targets-train.json

    python3 /model/replace_tokens.py \
    --source_data_path /mnt/staging/train.tsv \
    --dest_data_path /mnt/outputs/gradient-targeting/train.tsv \
    --mapping_json /mnt/staging/targets-train-gradient.json

    python3 /model/replace_tokens.py \
    --source_data_path /mnt/staging/train.tsv \
    --dest_data_path /mnt/outputs/random-targeting/train.tsv \
    --mapping_json /mnt/staging/targets-train-random.json
fi

time python3 /model/gradient_attack.py \
  --data_path /mnt/staging/test.tsv \
  --expt_dir /models/lstm \
  --load_checkpoint Best_F1 \
  --save_path /mnt/staging/targets-test.json \
  --random --distinct

python3 /model/replace_tokens.py \
  --source_data_path /mnt/staging/test.tsv \
  --dest_data_path /mnt/outputs/gradient-targeting/test.tsv \
  --mapping_json /mnt/staging/targets-test-gradient.json

python3 /model/replace_tokens.py \
  --source_data_path /mnt/staging/test.tsv \
  --dest_data_path /mnt/outputs/random-targeting/test.tsv \
  --mapping_json /mnt/staging/targets-test-random.json

echo "  + Done!"
