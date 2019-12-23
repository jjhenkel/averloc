#!/bin/bash

cd /cubix/cubix

# Do the build
stack build --ghc-options='-O0 -j +RTS -A256m -n2m -RTS' --allow-different-user

# Find the exe
TRANSFORM="$(find / -type f -name 'examples-java' | grep 'install' | head -n1)"

NUM_TRANSFORMS=3

# Run it
echo "Running transforms..."
while IFS="" read -r line; do
  THE_HASH="$(jq -r '.sha256_hash' <<< "${line}")"

  TMP_FILE=$(mktemp /tmp/java-pre.XXXXXX)
  jq -r '.source_code' <<< "${line}" > "${TMP_FILE}" 
  
  RESULTS=$("${TRANSFORM}" "${TMP_FILE}")
  for i in $(seq 0 $((${NUM_TRANSFORMS} - 1))); do
    echo "${RESULTS}" | jq -r ".[$i].result" > "/mnt/outputs/${THE_HASH}-$(
      echo "${RESULTS}" | jq -r ".[$i].transform"
    ).java"
  done
  echo "  + Transformed ${THE_HASH}"

  rm "${TMP_FILE}"
done < <(cat /mnt/inputs/test.jsonl.gz | gzip -cd)
