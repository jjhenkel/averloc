#!/bin/bash

TRANSFORMS="RenameFields RenameLocalVariables RenameParameters ReplaceTrueFalse InsertPrintStatements"

trap "echo Exited!; exit 1;" SIGINT SIGTERM

for THESET in test train valid; do
  
  rm -rf /tmp/*
  echo "Getting ${THESET} files setup..."
  cat /mnt/inputs/${THESET}.targets.histo.txt > /histo.txt
  while IFS="" read -r line; do
    THE_HASH="$(jq -r '.sha256_hash' <<< "${line}")"
    
    jq -r '.source_code' <<< "${line}" | \
      sed -e "s/class WRAPPER {/class WRAPPER_${THE_HASH} {/g" \
    > "/tmp/${THE_HASH}.java"
  done < <(cat /mnt/inputs/${THESET}.jsonl.gz | gzip -cd)
  echo "  + Done!"
  echo "Running transforms:"

  for TRANSFORMER in ${TRANSFORMS}; do

    echo "  - Running transform: '${TRANSFORMER}'"
    time java -XX:-UsePerfData -Xmx128g -d64 -cp /app/spoon.jar:/app Transforms \
      --input "/tmp" \
      --output "/mnt/outputs-raw/" \
      --processors "transforms.${TRANSFORMER}" \
      --output-type classes

    rm -f /mnt/outputs-raw/spoon-log.log 
    mkdir -p /mnt/outputs/${TRANSFORMER}

    echo "    + Transforms complete!"
    echo "    + Saving..."
    find /mnt/outputs-raw -type f -name "WRAPPER_*.java" -exec sh -c '
      for file do
        /app/util/jq -nc --rawfile source "${file}" "{ granularity: "\""file"\"", language: "\""java"\"", code: \$source }" | gzip
      done
    ' sh {} + > /mnt/outputs/${TRANSFORMER}/${THESET}.jsonl.gz
    echo "      + Data wrttien to /mnt/outputs/${TRANSFORMER}/${THESET}.jsonl.gz"

  done
done
