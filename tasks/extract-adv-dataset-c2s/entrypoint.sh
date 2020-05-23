#!/bin/bash

set -ex

mkdir -p /mnt/staging
mkdir -p /mnt/outputs/gradient-targeting
mkdir -p /mnt/outputs/random-targeting

NUM_T=$(($# - 1))

echo "[Step 1/2] Preparing data..."

cp /mnt/inputs/transforms.Identity/data.dict.c2s /mnt/outputs/gradient-targeting/data.dict.c2s
cp /mnt/inputs/transforms.Identity/data.dict.c2s /mnt/outputs/random-targeting/data.dict.c2s

FLAGS=""
if [ "${NO_RANDOM}" != "true" ]; then
  FLAGS="--random"
fi

if [ "${AVERLOC_JUST_TEST}" = "true" ]; then
    python3 /app/app.py test $@

    cp /mnt/staging/data0.test.c2s /mnt/outputs/gradient-targeting/data0.test.c2s
    cp /mnt/staging/data0.test.c2s /mnt/outputs/random-targeting/data0.test.c2s
else
    if [ "${NO_TEST}" != "true" ]; then
        python3 /app/app.py test $@

        cp /mnt/staging/data0.test.c2s /mnt/outputs/gradient-targeting/data0.test.c2s
        cp /mnt/staging/data0.test.c2s /mnt/outputs/random-targeting/data0.test.c2s
    fi
    python3 /app/app.py train $@
    
    cat /mnt/inputs/transforms.Identity/data.val.c2s | cut -d' ' -f2- > /mnt/outputs/gradient-targeting/data.val.c2s
    cat /mnt/inputs/transforms.Identity/data.val.c2s | cut -d' ' -f2- > /mnt/outputs/random-targeting/data.val.c2s

    cp /mnt/staging/data0.train.c2s /mnt/outputs/gradient-targeting/data0.train.c2s
    cp /mnt/staging/data0.train.c2s /mnt/outputs/random-targeting/data0.train.c2s
fi

echo "  + Done!"

echo "[Step 2/2] Doing taregting..."

SELECTED_MODEL=$(
  find /models \
    -type f \
    -name "model_iter*" \
  | awk -F'.' '{ print $1 }' \
  | sort -t 'r' -k 2 -n -u \
  | tail -n1
)

if [ "${AVERLOC_JUST_TEST}" != "true" ]; then
  for t in $(seq 1 ${NUM_T}); do
    time python3 /model/gradient_attack.py \
      --data /mnt/staging/data${t}.train.c2s \
      --load "${SELECTED_MODEL}" \
      --output_json_path /mnt/staging/${t}-targets-train.json \
      ${FLAGS}

    python3 /model/replace_tokens.py \
      --source_data_path /mnt/staging/data${t}.train.c2s \
      --dest_data_path /mnt/outputs/gradient-targeting/data${t}.train.c2s \
      --mapping_json /mnt/staging/${t}-targets-train-gradient.json

    if [ "${NO_RANDOM}" != "true" ]; then
      python3 /model/replace_tokens.py \
      --source_data_path /mnt/staging/data${t}.train.c2s \
      --dest_data_path /mnt/outputs/random-targeting/data${t}.train.c2s \
      --mapping_json /mnt/staging/${t}-targets-train-random.json
    fi
  done
fi

if [ "${NO_TEST}" != "true" ]; then
  for t in $(seq 1 ${NUM_T}); do
    time python3 /model/gradient_attack.py \
      --data /mnt/staging/data${t}.test.c2s \
      --load "${SELECTED_MODEL}" \
      --output_json_path /mnt/staging/${t}-targets-test.json \
      ${FLAGS}

    python3 /model/replace_tokens.py \
      --source_data_path /mnt/staging/data${t}.test.c2s \
      --dest_data_path /mnt/outputs/gradient-targeting/data${t}.test.c2s \
      --mapping_json /mnt/staging/${t}-targets-test-gradient.json

    if [ "${NO_RANDOM}" != "true" ]; then
      python3 /model/replace_tokens.py \
      --source_data_path /mnt/staging/data${t}.test.c2s \
      --dest_data_path /mnt/outputs/random-targeting/data${t}.test.c2s \
      --mapping_json /mnt/staging/${t}-targets-test-random.json
    fi
  done
fi

echo "  + Done!"
