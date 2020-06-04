#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "attackName,randTargFOneDrop,gradTargFOneDrop,randTargFOneDropCS,gradTargFOneDropCS"

THE_PATH="${DIR}/seq2seq/c2s/java-small/normal-model/depth-1-random-attack/log-normal.txt"
F1_BASE=$(grep -Po 'f1: \d+.\d+' "${THE_PATH}" | awk '{ print $2 }')

THE_PATH_C2S="${DIR}/code2seq/c2s/java-small/normal-model/no-attack/log-normal.txt"
F1_BASE_C2S=$(grep -Po 'F1: \d+.\d+' "${THE_PATH_C2S}" | awk '{ print 100.0*$2 }')

for attack in AddDeadCode InsertPrintStatements RenameFields RenameLocalVariables RenameParameters ReplaceTrueFalse UnrollWhiles WrapTryCatch; do
  CLEAN_NAME=${attack%"s"}
  RAND_PATH="${DIR}/individual-attacks/c2s-java/normal-model/${attack}/random/log.txt"
  GRAD_PATH="${DIR}/individual-attacks/c2s-java/normal-model/${attack}/gradient/log.txt"
  F1_RAND=$(grep -Po 'f1: \d+.\d+' "${RAND_PATH}" | awk "{ print $F1_BASE - \$2 }" | sed -e "s/^-0\./0./")
  F1_GRAD=$(grep -Po 'f1: \d+.\d+' "${GRAD_PATH}" | awk "{ print $F1_BASE - \$2 }" | sed -e "s/^-0\./0./")

  RAND_PATH_C2S="${DIR}/individual-attacks/code2seq/c2s-java/normal-model/${attack}/random/log-normal.txt"
  GRAD_PATH_C2S="${DIR}/individual-attacks/code2seq/c2s-java/normal-model/${attack}/gradient/log-normal.txt"
  F1_RAND_C2S=$(grep -Po 'F1: \d+.\d+' "${RAND_PATH_C2S}" | awk "{ print $F1_BASE_C2S - 100.0*\$2 }" | sed -e "s/^-0\./0./")
  F1_GRAD_C2S=$(grep -Po 'F1: \d+.\d+' "${GRAD_PATH_C2S}" | awk "{ print $F1_BASE_C2S - 100.0*\$2 }" | sed -e "s/^-0\./0./")
  printf "%s,%.1f,%.1f,%.1f,%.1f\n" ${CLEAN_NAME} "${F1_RAND}" "${F1_GRAD}" "${F1_RAND_C2S}" "${F1_GRAD_C2S}"
done
