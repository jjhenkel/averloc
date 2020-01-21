#!/bin/bash

python3 /app/app.py $@

cp /mnt/inputs/transforms.Identity/valid.tsv /mnt/outputs/valid.tsv
cp /mnt/inputs/transforms.Identity/test.tsv /mnt/outputs/test.tsv
