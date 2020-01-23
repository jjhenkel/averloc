#!/bin/sh

set -ex

mkdir -p /mnt/outputs

python /model/train_adv.py \
  --train_path /mnt/inputs/train.tsv \
  --dev_path /mnt/inputs/valid.tsv \
  --expt_name lstm \
  --expt_dir /mnt/outputs $@

# python train.py --train_path data/java-small/transforms.Identity/train.tsv --dev_path data/java-small/transforms.Identity/valid.tsv --expt_name java_small_identity  --resume --expt_dir experiment/java_small_identity --load_checkpoint Best_F1
