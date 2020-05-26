# Experimental Procedure

The following document has examples of how to invoke the many sub-commands in this repository to carry out
experiments related to AdVERsarial Learning On Code (`averloc`).

## `seq2seq` models

Details on commands used to drive training/eval. for `seq2seq` models in `averloc`.

### Normal Training

Trains `seq2seq` models on our four normal datasets. Uses data from `transforms.Identity` to aid in
more consistent evaluation. For example, if the transforms framework un-parser were to produce stylistically
different code, we normalize for that by training/testing on data that's passed through the transforms framework
even though we could just used the "normal" un-transformed datasets here.

```bash
# Replace $THE_GPU with a free gpu (usually doing this on K80s, GTX 2080TIs, or V100s)
ARGS="--regular_training --epochs 10" \
GPU=$THE_GPU \
MODELS_OUT=final-models/seq2seq/c2s/java-small \
DATASET_NAME=datasets/transformed/preprocessed/tokens/c2s/java-small/transforms.Identity \
time make train-model-seq2seq

ARGS="--regular_training --epochs 10" \
GPU=$THE_GPU \
MODELS_OUT=final-models/seq2seq/csn/java \
DATASET_NAME=datasets/transformed/preprocessed/tokens/csn/java/transforms.Identity \
time make train-model-seq2seq

ARGS="--regular_training --epochs 10" \
GPU=$THE_GPU \
MODELS_OUT=final-models/seq2seq/csn/python \
DATASET_NAME=datasets/transformed/preprocessed/tokens/csn/python/transforms.Identity \
time make train-model-seq2seq

ARGS="--regular_training --epochs 10" \
GPU=$THE_GPU \
MODELS_OUT=final-models/seq2seq/sri/py150 \
DATASET_NAME=datasets/transformed/preprocessed/tokens/sri/py150/transforms.Identity \
time make train-model-seq2seq
```

### Normal Testing (no-attack)

Batch size here needs to be tuned. When we're testing there is _no filtering_ of inputs of exceedingly long length. Ideally, we'd have some sort of adaptive-batching that allowed for larger batches where inputs were small and then gradually reduced the batch size.

```bash
# Replace $THE_GPU with a free gpu (usually doing this on K80s, GTX 2080TIs, or V100s)
GPU=$THE_GPU \
ARGS='--no-attack --batch_size 64' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/transformed/preprocessed/tokens/c2s/java-small/transforms.Identity \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/normal-model/no-attack \
MODELS_IN=final-models/seq2seq/c2s/java-small/normal \
time make test-model-seq2seq

GPU=$THE_GPU \
ARGS='--no-attack --batch_size 64' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/transformed/preprocessed/tokens/csn/java/transforms.Identity \
RESULTS_OUT=final-results/seq2seq/csn/java/normal-model/no-attack \
MODELS_IN=final-models/seq2seq/csn/java/normal \
time make test-model-seq2seq

GPU=$THE_GPU \
ARGS='--no-attack --batch_size 64' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/transformed/preprocessed/tokens/csn/python/transforms.Identity \
RESULTS_OUT=final-results/seq2seq/csn/python/normal-model/no-attack \
MODELS_IN=final-models/seq2seq/csn/python/normal \
time make test-model-seq2seq

GPU=$THE_GPU \
ARGS='--no-attack --batch_size 64' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/transformed/preprocessed/tokens/sri/py150/transforms.Identity \
RESULTS_OUT=final-results/seq2seq/sri/py150/normal-model/no-attack \
MODELS_IN=final-models/seq2seq/sri/py150/normal \
time make test-model-seq2seq
```

### Random-targeting/Gradient-targeting Testing (attacks)

First, as a pre-requisite, doing this requires _targeting_ the test set to the model under test (that's part of the "attack"---doing some level of targeting whether it be gradient-based or totally random).

```bash
# Example targeting of normal model on the c2s/java-small test set
# Note, adv. models are often using CHECKPOINT="Latest" whereas normal
# models (right now) just save "Best_F1".
GPU=$THE_GPU \
CHECKPOINT="Best_F1" \
NO_RANDOM="false" \
NO_GRADIENT="false" \
NO_TEST="false" \
AVERLOC_JUST_TEST="true" \
SHORT_NAME="depth-1-attack" \
DATASET="c2s/java-small" \
MODELS_IN=final-models/seq2seq/c2s/java-small/normal \
TRANSFORMS='transforms\.\w+' \
  time make extract-adv-dataset-tokens
```

```bash
# Same thing but for depth-5
GPU=0 CHECKPOINT="Best_F1" NO_RANDOM="false" NO_GRADIENT="false" NO_TEST="false" AVERLOC_JUST_TEST="true" SHORT_NAME="depth-5-attack" DATASET="csn/python" MODELS_IN=final-models/seq2seq/csn/python/normal TRANSFORMS='(transforms\.Identity|depth-5-.*)' time make extract-adv-dataset-tokens
```

Next, we can do the evaluation (batched attack-eval used here, not normal eval).

```bash
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/c2s/java-small/random-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/normal-model/random-attack \
MODELS_IN=final-models/seq2seq/c2s/java-small/normal \
time make test-model-seq2seq && \
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/c2s/java-small/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/normal-model/gradient-attack \
MODELS_IN=final-models/seq2seq/c2s/java-small/normal \
time make test-model-seq2seq && \
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/csn/java/random-targeting \
RESULTS_OUT=final-results/seq2seq/csn/java/normal-model/random-attack \
MODELS_IN=final-models/seq2seq/csn/java/normal \
time make test-model-seq2seq && \
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/csn/java/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/csn/java/normal-model/gradient-attack \
MODELS_IN=final-models/seq2seq/csn/java/normal \
time make test-model-seq2seq

GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/csn/python/random-targeting \
RESULTS_OUT=final-results/seq2seq/csn/python/normal-model/random-attack \
MODELS_IN=final-models/seq2seq/csn/python/normal \
time make test-model-seq2seq && \
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/csn/python/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/csn/python/normal-model/gradient-attack \
MODELS_IN=final-models/seq2seq/csn/python/normal \
time make test-model-seq2seq && \
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/sri/py150/random-targeting \
RESULTS_OUT=final-results/seq2seq/sri/py150/normal-model/random-attack \
MODELS_IN=final-models/seq2seq/sri/py150/normal \
time make test-model-seq2seq && \
GPU=$THE_GPU \
ARGS='--batch_size 32' \
CHECKPOINT=Best_F1 \
DATASET_NAME=datasets/adversarial/depth-1-attack/tokens/sri/py150/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/sri/py150/normal-model/gradient-attack \
MODELS_IN=final-models/seq2seq/sri/py150/normal \
time make test-model-seq2seq
```

## `code2seq` models

Details on commands used to drive training/eval. for `code2seq` models in `averloc`.

### Normal Training


### Normal Testing (no-attack)



## Lambda / Adv. Train Type Grid Search

This was all done on a _single_ dataset: `c2s/java-small` and a _single_
model: `seq2seq`. It wouldn't really be feasible (or necessary) to do this for all datasets and models.

### Targeting for models with `fine-tuning=yes` and `per-epoch=no`

```bash
# TODO (did this earlier)
```

### Testing for models with `fine-tuning=yes` and `per-epoch=no`

```bash
GPU=0 \
ARGS='--batch_size 32' \
CHECKPOINT=Latest \
DATASET_NAME=datasets/adversarial/depth-1-test-for-adv-l0.1/tokens/c2s/java-small/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/adversarial-model/ft-yes-pe-no-lamb-0.1/depth-1-gradient-attack \
MODELS_IN=trained-models/seq2seq/lamb-0.1/c2s/java-small/adversarial \
time make test-model-seq2seq

GPU=0 \
ARGS='--batch_size 32' \
CHECKPOINT=Latest \
DATASET_NAME=datasets/adversarial/depth-1-test-for-adv-l0.2/tokens/c2s/java-small/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/adversarial-model/ft-yes-pe-no-lamb-0.2/depth-1-gradient-attack \
MODELS_IN=trained-models/seq2seq/lamb-0.2/c2s/java-small/adversarial \
time make test-model-seq2seq

GPU=0 \
ARGS='--batch_size 32' \
CHECKPOINT=Latest \
DATASET_NAME=datasets/adversarial/depth-1-test-for-adv-l0.3/tokens/c2s/java-small/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/adversarial-model/ft-yes-pe-no-lamb-0.3/depth-1-gradient-attack \
MODELS_IN=trained-models/seq2seq/lamb-0.3/c2s/java-small/adversarial \
time make test-model-seq2seq

GPU=0 \
ARGS='--batch_size 32' \
CHECKPOINT=Latest \
DATASET_NAME=datasets/adversarial/depth-1-test-for-adv-l0.4/tokens/c2s/java-small/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/adversarial-model/ft-yes-pe-no-lamb-0.4/depth-1-gradient-attack \
MODELS_IN=trained-models/seq2seq/lamb-0.4/c2s/java-small/adversarial \
time make test-model-seq2seq

GPU=0 \
ARGS='--batch_size 32' \
CHECKPOINT=Latest \
DATASET_NAME=datasets/adversarial/depth-1-test-for-adv-l0.5/tokens/c2s/java-small/gradient-targeting \
RESULTS_OUT=final-results/seq2seq/c2s/java-small/adversarial-model/ft-yes-pe-no-lamb-0.5/depth-1-gradient-attack \
MODELS_IN=trained-models/seq2seq/lamb-0.5/c2s/java-small/adversarial \
time make test-model-seq2seq
```

### Targeting for models with `fine-tuning=no` and `per-epoch=no`

```bash
# TODO (did this earlier)
```

### Testing for models with `fine-tuning=no` and `per-epoch=no`

```bash
# TODO (did this earlier)
```

### Targeting for models with `fine-tuning=no` and `per-epoch=yes`

```bash
# TODO (did this earlier)
```

### Testing for models with `fine-tuning=no` and `per-epoch=yes`

```bash
# TODO (did this earlier)
```
