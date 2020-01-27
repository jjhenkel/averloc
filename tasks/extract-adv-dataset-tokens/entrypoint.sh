#!/bin/bash

set -ex
if [ "${AVERLOC_JUST_TEST}" = "true" ]; then
    python3 /app/app.py test $@
else
    python3 /app/app.py test $@
    python3 /app/app.py train $@

    cat /mnt/inputs/transforms.Identity/valid.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/valid.tsv
fi
