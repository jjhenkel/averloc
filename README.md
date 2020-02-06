# averloc (AdVERsarial Learning On Code)

Repository for Semantic Robustness of Models on Source Code.

## Directory Structure

In this repository, we have the following directories:

### `./datasets`

**Note:** the datasets are all much too large to be included in this GitHub repo. This is simply the
structure as it would exist on disk once our framework is setup.

```bash
./datasets
  + ./raw            # The four datasets in "raw" form
  + ./normalized     # The four datasets in the "normalized" JSON-lines representation 
  + ./preprocess
    + ./tokens       # The four datasets in a representation suitable for token-level models
    + ./ast-paths    # The four datasets in a representation suitable for code2seq
  + ./transformed    # The four datasets transformed via our code-transformation framework 
    + ./normalized   # Transformed datasets normalized back into the JSON-lines representation
    + ./preprocessed # Transformed datasets preprocessed into:
      + ./tokens     # ... a representation suitable for token-level models
      + ./ast-paths  # ... a representation suitable for code2seq
  + ./adversarial    # Datasets in the format < source, target, tranformed-variant #1, #2, ..., #K >
    + ./tokens       # ... in a token-level representation
    + ./ast-paths    # ... in an ast-paths representation
```

## `./models`

We have two Machine Learning on Code models. Both of them are trained on the Code Summarization task. The
seq2seq model has been modified to include an adversarial training loop and a way to compute Integrated Gradients.
The code2seq model has been modified to include an adversarial training loop and emit attention weights.

```bash
./models
  + ./code2seq         # seq2seq model implementation
  + ./pytorch-seq2seq  # code2seq model implementation
```

## `./results`

This directory stores results that are small-enough to be checked into GitHub. In addition, a few utility scripts
live here.

## `./scratch`

This directory contains exploratory data analysis and evaluations that did not fit into the overall workflow of our
code-transformation + adversarial training framework. For instance, HTML-based visualizations of Integrated Gradients
and attention exist in this directory.

## `./scripts`

In this directory there are a large number of scripts for doing various chores related to running and maintaing
this code transformation infrastructure.

## `./tasks`

This directory houses the implementations of various pieces of our core framework:

```bash
./tasks
  + ./astor-apply-transforms
  + ./depth-k-test-seq2seq
  + ./download-c2s-dataset
  + ./download-csn-dataset
  + ./extract-adv-dataset-c2s
  + ./extract-adv-dataset-tokens
  + ./generate-baselines
  + ./integrated-gradients-seq2seq
  + ./normalize-raw-dataset
  + ./preprocess-dataset-c2s
  + ./preprocess-dataset-tokens
  + ./spoon-apply-transforms
  + ./test-model-code2seq
  + ./test-model-seq2seq
  + ./train-model-code2seq
  + ./train-model-seq2seq
```

## `./vendor`

This directory contains dependencies in the form of git submodukes.

## `Makefile`

We have one overarching `Makefile` that can be used to drive a number of the data generation, training, testing, adn evaluation tasks.

```
download-datasets                  (DS-1) Downloads all prerequisite datasets
normalize-datasets                 (DS-2) Normalizes all downloaded datasets
extract-ast-paths                  (DS-3) Generate preprocessed data in a form usable by code2seq style models. 
extract-tokens                     (DS-3) Generate preprocessed data in a form usable by seq2seq style models. 
apply-transforms-c2s-java-med      (DS-4) Apply our suite of transforms to code2seq's java-med dataset.
apply-transforms-c2s-java-small    (DS-4) Apply our suite of transforms to code2seq's java-small dataset.
apply-transforms-csn-java          (DS-4) Apply our suite of transforms to CodeSearchNet's java dataset.
apply-transforms-csn-python        (DS-4) Apply our suite of transforms to CodeSearchNet's python dataset.
apply-transforms-sri-py150         (DS-4) Apply our suite of transforms to SRI Lab's py150k dataset.
extract-transformed-ast-paths      (DS-6) Extract preprocessed representations (ast-paths) from our transfromed (normalized) datasets 
extract-transformed-tokens         (DS-6) Extract preprocessed representations (tokens) from our transfromed (normalized) datasets 
extract-adv-datasets-tokens        (DS-7) Extract preprocessed adversarial datasets (representations: tokens)
do-integrated-gradients-seq2seq    (IG) Do IG for our seq2seq model
docker-cleanup                     (MISC) Cleans up old and out-of-sync Docker images.
submodules                         (MISC) Ensures that submodules are setup.
help                               (MISC) This help.
test-model-code2seq                (TEST) Tests the code2seq model on a selected dataset.
test-model-seq2seq                 (TEST) Tests the seq2seq model on a selected dataset.
train-model-code2seq               (TRAIN) Trains the code2seq model on a selected dataset.
train-model-seq2seq                (TRAIN) Trains the seq2seq model on a selected dataset.
```
