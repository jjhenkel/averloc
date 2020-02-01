#!/bin/bash

set -ex

export GPU=0

THE_DS=$1

DATASET_NAME=datasets/transformed/preprocessed/tokens/${THE_DS}/transforms.Identity \
RESULTS_OUT=c2s-test-results/${THE_DS}/normal/normal \
MODELS_IN=trained-models/code2seq/${THE_DS}/normal \
ARGS="--no-attack ${ARGS}" \
time make test-model-code2seq

DATASET_NAME=datasets/transformed/preprocessed/tokens/${THE_DS}/transforms.Identity \
RESULTS_OUT=c2s-test-results/${THE_DS}/adversarial-all/normal \
MODELS_IN=trained-models/code2seq/${THE_DS}/adversarial-all \
ARGS="--no-attack ${ARGS}" \
time make test-model-code2seq

DATASET_NAME=datasets/transformed/preprocessed/tokens/${THE_DS}/transforms.Identity \
RESULTS_OUT=c2s-test-results/${THE_DS}/adversarial-one-step/normal \
MODELS_IN=trained-models/code2seq/${THE_DS}/adversarial-one-step \
ARGS="--no-attack ${ARGS}" \
time make test-model-code2seq
