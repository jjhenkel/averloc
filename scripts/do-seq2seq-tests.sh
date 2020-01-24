#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

OUTPUT_DIR="results/01-24-2020"

SETS="c2s/java-small csn/java csn/python"

MODELS="adversarial adversarial-all normal"

TESTS_SOURCE="datasets/transformed/preprocessed/tokens"

for the_set in ${SETS}; do
  for the_model in ${MODELS}; do
    for the_test in $(find ${TESTS_SOURCE}/${the_set} -type d); do
      results_dir="${OUTPUT_DIR}/${the_set}/${the_model}/$(basename ${the_test})"
      mkdir -p "${results_dir}"

      set -x  
      RESULTS_OUT="${results_dir}" \
      MODELS_IN="trained-models/${the_set}/${the_model}" \
      DATASET_NAME="${the_test}" \
      ARGS="$@" \
        time  make test-model-seq2seq 
      set +x

    done
  done
done
