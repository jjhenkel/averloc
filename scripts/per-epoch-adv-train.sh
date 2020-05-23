#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

trap "echo '[ADV-TRAIN]  - CTRL-C Pressed. Quiting...'; exit;" SIGINT SIGTERM

pushd "${DIR}/.." > /dev/null

export MAX_EPOCHS=10
export DATASET=c2s/java-small

echo "[ADV-TRAIN] Copying over normal model for first-round targeting..."
mkdir -p "trained-models/seq2seq/per-epoch-l${2}/${DATASET}/adversarial/lstm"
docker run -it --rm \
  -v "${DIR}/../trained-models/seq2seq/${DATASET}/normal":/mnt/inputs \
  -v "${DIR}/../trained-models/seq2seq/per-epoch-l${2}/${DATASET}/adversarial":/mnt/outputs \
  debian:9 \
    bash -c 'cp -r /mnt/inputs/lstm/checkpoints /mnt/outputs/lstm && mv /mnt/outputs/lstm/checkpoints/Best_F1 /mnt/outputs/lstm/checkpoints/Latest'
echo "[ADV-TRAIN]   + Done!"

echo "[ADV-TRAIN] Starting loop..."

for epoch in $(seq 1 ${MAX_EPOCHS}); do
echo "[ADV-TRAIN]   + Epoch ${epoch} targeting begins..."

CHECKPOINT="Latest" \
NO_RANDOM="true" \
NO_TEST="true" \
SHORT_NAME="d1-train-epoch-${epoch}-l${2}" \
GPU="${1}" \
MODELS_IN=trained-models/seq2seq/per-epoch-l${2}/${DATASET}/adversarial \
TRANSFORMS='transforms\.\w+' \
  time make extract-adv-dataset-tokens-c2s-java-small

echo "[ADV-TRAIN]     + Targeting complete!"
echo "[ADV-TRAIN]   + Epoch ${epoch} training begins..."

ARGS="${DO_FINETUNE} --epochs 1 --lamb ${2}" \
SHORT_NAME="d1-train-epoch-${epoch}-l${2}" \
GPU="${1}" \
MODELS_OUT=trained-models/seq2seq/per-epoch-l${2}/${DATASET} \
DATASET_NAME=datasets/adversarial/${SHORT_NAME}/tokens/${DATASET}/gradient-targeting \
  time make adv-train-model-seq2seq
echo "[ADV-TRAIN]     + Training epoch complete!"

export DO_FINETUNE="--adv_fine_tune"
done

echo "[ADV-TRAIN]  + Training finished!"

popd > /dev/null
