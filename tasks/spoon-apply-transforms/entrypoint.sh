#!/bin/bash

trap "echo Exited!; exit 1;" SIGINT SIGTERM

echo "Running transforms..."
cat /mnt/inputs/test.targets.histo.txt > /histo.txt
while IFS="" read -r line; do
  TRANSFORMER="RenameParameters"

  THE_HASH="$(jq -r '.sha256_hash' <<< "${line}")"

  TMP_FILE=$(mktemp /tmp/XXX-XXX-XXX.java)

  jq -r '.source_code' <<< "${line}" > "${TMP_FILE}" 

  cat "${TMP_FILE}"
  echo "-----------------------------------------------------------------------"

  java -XX:-UsePerfData -Xmx128g -d64 -cp /app/spoon.jar:/app Transforms \
    --input "${TMP_FILE}" \
    --output "/mnt/outputs-raw/" \
    --processors "transforms.${TRANSFORMER}" \
    --output-type classes

  echo "-----------------------------------------------------------------------"

  rm -f /mnt/outputs-raw/spoon-log.log 

  mv /mnt/outputs-raw/WRAPPER.java "/mnt/outputs-raw/${THE_HASH}.${TRANSFORMER}.java"

  cat "/mnt/outputs-raw/${THE_HASH}.${TRANSFORMER}.java"
  echo "-----------------------------------------------------------------------"

  echo "  + Transformed ${THE_HASH}"

  rm "${TMP_FILE}"
done < <(cat /mnt/inputs/test.jsonl.gz | gzip -cd | head -n20)
# TODO: ^ head -n10 REMOVE JUST FOR DEBUG