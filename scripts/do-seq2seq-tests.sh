#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -ex

OUTPUT_DIR="results/01-24-2020"

SETS="c2s/java-small csn/java csn/python"

MODELS="adversarial adversarial-all normal"

TESTS_SOURCE="datasets/transformed/preprocessed/tokens"

for the_set in ${SETS}; do
  for the_model in ${MODELS}; do
    for the_test in $(find ${TESTS_SOURCE}/${the_set} -type d); do
      RESULTS_OUT="${OUTPUT_DIR}/${the_set}/${the_model}/$(basename ${the_test})"
      mkdir -p "${RESULTS_OUT}"
      DATASET_NAME="${the_test}"
      MODELS_IN="trained-models/${the_set}/${the_model}"
      time make test-model-seq2seq $@
    done
  done
done
