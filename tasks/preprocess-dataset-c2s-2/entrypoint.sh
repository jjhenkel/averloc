#!/bin/bash

###########################################################
# Change the following values to preprocess a new dataset.
# DATASET_NAME is just a name for the currently extracted 
#   dataset.                                              
# MAX_DATA_CONTEXTS is the number of contexts to keep in the dataset for each 
#   method (by default 1000). At training time, these contexts
#   will be downsampled dynamically to MAX_CONTEXTS.
# MAX_CONTEXTS - the number of actual contexts (by default 200) 
# that are taken into consideration (out of MAX_DATA_CONTEXTS)
# every training iteration. To avoid randomness at test time, 
# for the test and validation sets only MAX_CONTEXTS contexts are kept 
# (while for training, MAX_DATA_CONTEXTS are kept and MAX_CONTEXTS are
# selected dynamically during training).
# SUBTOKEN_VOCAB_SIZE, TARGET_VOCAB_SIZE -   
#   - the number of subtokens and target words to keep 
#   in the vocabulary (the top occurring words and paths will be kept). 
# NUM_THREADS - the number of parallel threads to use. It is 
#   recommended to use a multi-core machine for the preprocessing 
#   step and set this value to the number of cores.
# PYTHON - python3 interpreter alias.
DATASET_NAME=my_dataset
MAX_DATA_CONTEXTS=1000
MAX_CONTEXTS=200
SUBTOKEN_VOCAB_SIZE=186277
TARGET_VOCAB_SIZE=26347
NUM_THREADS=64
PYTHON=python3
###########################################################

mkdir -p /mnt/outputs

TRAIN_DATA_FILE=/mnt/outputs/train.raw.txt
VAL_DATA_FILE=/mnt/outputs/valid.raw.txt
TEST_DATA_FILE=/mnt/outputs/test.raw.txt
EXTRACTOR_JAR=/code2seq/JavaExtractor/JPredict/target/JavaExtractor-0.0.1-SNAPSHOT.jar

echo "Extracting paths from validation set..."
cat /mnt/inputs/valid/path_contexts*.csv > ${VAL_DATA_FILE}
echo "Finished extracting paths from validation set"
echo "Extracting paths from test set..."
cat /mnt/inputs/test/path_contexts*.csv > ${TEST_DATA_FILE}
echo "Finished extracting paths from test set"
echo "Extracting paths from training set..."
cat /mnt/inputs/train/path_contexts*.csv > ${TRAIN_DATA_FILE}
echo "Finished extracting paths from training set"

TARGET_HISTOGRAM_FILE=/mnt/outputs/histo.tgt.c2s
SOURCE_SUBTOKEN_HISTOGRAM=/mnt/outputs/histo.ori.c2s
NODE_HISTOGRAM_FILE=/mnt/outputs/histo.node.c2s

echo "Creating histograms from the training data"
cat ${TRAIN_DATA_FILE} | cut -d' ' -f1 | tr '|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${TARGET_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f1,3 | tr ',|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${SOURCE_SUBTOKEN_HISTOGRAM}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f2 | tr '|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${NODE_HISTOGRAM_FILE}

${PYTHON} /code2seq/preprocess.py --train_data ${TRAIN_DATA_FILE} --test_data ${TEST_DATA_FILE} --val_data ${VAL_DATA_FILE} \
  --max_contexts ${MAX_CONTEXTS} --max_data_contexts ${MAX_DATA_CONTEXTS} --subtoken_vocab_size ${SUBTOKEN_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --subtoken_histogram ${SOURCE_SUBTOKEN_HISTOGRAM} \
  --node_histogram ${NODE_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --output_name /mnt/outputs/data

# If all went well, the raw data files can be deleted, because preprocess.py creates new files 
# with truncated and padded number of paths for each example.
rm ${TRAIN_DATA_FILE} ${VAL_DATA_FILE} ${TEST_DATA_FILE} ${TARGET_HISTOGRAM_FILE} ${SOURCE_SUBTOKEN_HISTOGRAM} \
  ${NODE_HISTOGRAM_FILE}

