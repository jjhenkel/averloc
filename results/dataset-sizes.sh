#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "repr,dataset,trainSize,valSize,testSize"
for DATASET in c2s/java-small csn/java sri/py150 csn/python; do
  TRN_SIZE=$(cat "${DIR}/../datasets/transformed/preprocessed/tokens/${DATASET}/transforms.Identity/train.tsv" | wc -l)  
  VAL_SIZE=$(cat "${DIR}/../datasets/transformed/preprocessed/tokens/${DATASET}/transforms.Identity/valid.tsv" | wc -l)   
  TST_SIZE=$(cat "${DIR}/../datasets/transformed/preprocessed/tokens/${DATASET}/transforms.Identity/test.tsv" | wc -l)

  echo tokens,${DATASET},$(awk "BEGIN{printf \"%.1fk\", ($TRN_SIZE-1)/1000}"),$(awk "BEGIN{printf \"%.1fk\", ($VAL_SIZE-1)/1000}"),$(awk "BEGIN{printf \"%.1fk\", ($TST_SIZE-1)/1000}")
done
for DATASET in c2s/java-small csn/java sri/py150 csn/python; do
  TRN_SIZE=$(cat "${DIR}/../datasets/transformed/preprocessed/ast-paths/${DATASET}/transforms.Identity/data.train.c2s" | wc -l)  
  VAL_SIZE=$(cat "${DIR}/../datasets/transformed/preprocessed/ast-paths/${DATASET}/transforms.Identity/data.val.c2s" | wc -l)   
  TST_SIZE=$(cat "${DIR}/../datasets/transformed/preprocessed/ast-paths/${DATASET}/transforms.Identity/data.test.c2s" | wc -l)

  echo ast-paths,${DATASET},$(awk "BEGIN{printf \"%.1fk\", ($TRN_SIZE-1)/1000}"),$(awk "BEGIN{printf \"%.1fk\", ($VAL_SIZE-1)/1000}"),$(awk "BEGIN{printf \"%.1fk\", ($TST_SIZE-1)/1000}")
done
for DATASET in c2s/java-small csn/java sri/py150 csn/python; do
  TRN_SIZE=$(cat "${DIR}/../datasets/normalized/${DATASET}/train.jsonl.gz" | gzip -cd | wc -l)  
  VAL_SIZE=$(cat "${DIR}/../datasets/normalized/${DATASET}/valid.jsonl.gz" | gzip -cd | wc -l)   
  TST_SIZE=$(cat "${DIR}/../datasets/normalized/${DATASET}/test.jsonl.gz" | gzip -cd | wc -l)

  echo normalized,${DATASET},$(awk "BEGIN{printf \"%.1fk\", $TRN_SIZE/1000}"),$(awk "BEGIN{printf \"%.1fk\", $VAL_SIZE/1000}"),$(awk "BEGIN{printf \"%.1fk\", $TST_SIZE/1000}")
done
for DATASET in c2s/java-small csn/java sri/py150 csn/python; do
  TRN_SIZE=$(cat "${DIR}/../datasets/raw/${DATASET}/train.jsonl.gz" | gzip -cd | wc -l)  
  VAL_SIZE=$(cat "${DIR}/../datasets/raw/${DATASET}/valid.jsonl.gz" | gzip -cd | wc -l)   
  TST_SIZE=$(cat "${DIR}/../datasets/raw/${DATASET}/test.jsonl.gz" | gzip -cd | wc -l)

  echo raw,${DATASET},$(awk "BEGIN{printf \"%.1fk\", $TRN_SIZE/1000}"),$(awk "BEGIN{printf \"%.1fk\", $VAL_SIZE/1000}"),$(awk "BEGIN{printf \"%.1fk\", $TST_SIZE/1000}")
done

