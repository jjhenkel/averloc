#!/bin/bash

python3 /app/app.py $@

cat /mnt/inputs/transforms.Identity/valid.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/valid.tsv
cat /mnt/inputs/transforms.Identity/test.tsv | awk -F'\t' '{ print $2 "\t" $3 }' > /mnt/outputs/test.tsv
