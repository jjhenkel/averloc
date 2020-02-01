#!/bin/bash

set -ex
export PATH_PREFIX=true

if [ "${1}" = "--no-attack" ]; then

  echo "Skipping attack.py"
  shift
  python3 /code2seqORIG/code2seq.py \
    --load /models/model.final_iter15 \
    --test /mnt/inputs/data.test.c2s

else

  T="${1}"
  shift
  python3 /code2seqADVR/code2seq.py \
    --load /models/model.final_iter15 \
    -td /mnt/inputs \
    --adv_eval \
    -t "${T}" \
    -bs 1

fi
