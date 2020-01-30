#!/bin/bash

set -ex

if [ "${1}" = "--regular_training" ]; then

  shift
  python3 -u /code2seqORIG/code2seq.py \
    --data "/mnt/inputs/data" \
    --test "/mnt/inputs/data.val.c2s" \
    --save_prefix /mnt/outputs \
    $@

else

  T="${1}"
  shift
  python3 -u /code2seqADVR/code2seq.py \
    --data "/mnt/inputs/data" \
    --test "/mnt/inputs/data.val.c2s" \
    -td "/mnt/inputs" \
    -t "${T}" \
    --save_prefix /mnt/outputs \
    $@

fi
