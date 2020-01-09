#!/bin/sh
set -x
# python sample.py --train_path data/en-fr/europarl-v7.fr-en.val.tsv --dev_path data/en-fr/europarl-v7.fr-en.val.tsv
python sample.py --train_path data/en-fr/europarl-v7.fr-en.train.tsv --dev_path data/en-fr/europarl-v7.fr-en.val.tsv