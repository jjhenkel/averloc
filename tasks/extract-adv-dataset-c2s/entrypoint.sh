#!/bin/bash

set -ex

cp /mnt/inputs/transforms.Identity/data.dict.c2s /mnt/outputs/data.dict.c2s

if [ "${AVERLOC_JUST_TEST}" = "true" ]; then
    python3 /app/app.py test $@
else
    python3 /app/app.py test $@
    python3 /app/app.py train $@
    
    cat /mnt/inputs/transforms.Identity/data.val.c2s | cut -d' ' -f2- > /mnt/outputs/data.val.c2s
fi
