#!/bin/bash

trap "echo Exited!; exit 1;" SIGINT SIGTERM

echo "Running transforms..."
while IFS="" read -r line; do
  THE_HASH="$(jq -r '.sha256_hash' <<< "${line}")"

  TMP_FILE=$(mktemp /tmp/XXX-XXX-XXX.java)

  echo -n "public " > "${TMP_FILE}" 
  jq -r '.source_code' <<< "${line}" >> "${TMP_FILE}" 

  java -XX:-UsePerfData -cp /app/spoon.jar:/app Transforms \
    --input "${TMP_FILE}" \
    --output "/mnt/outputs-raw/" \
    --processors "transforms.AddDeadCodeAtBeginning" \
    --output-type classes \
    --compile

  rm -f /mnt/outputs-raw/spoon-log.log 

  mv /mnt/outputs-raw/WRAPPER.java "/mnt/outputs-raw/${THE_HASH}.AddDeadCodeAtBeginning.java"

  echo "  + Transformed ${THE_HASH}"

  rm "${TMP_FILE}"
done < <(cat /mnt/inputs/test.jsonl.gz | gzip -cd)
