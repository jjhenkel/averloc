#!/bin/bash

echo "Setting up dataset from '${DATASET_URL}'..."

echo "  - Downloading raw dataset..."
curl "${DATASET_URL}" | tar -xz -C "/tmp"
echo "    + Downloaded!"

echo "  - Creating 'test.jsonl.gz'..."
find /tmp/*/test -type f -exec sh -c '
  for file do
    /jq -nc --rawfile source "${file}" "{ granularity: "\""file"\"", language: "\""java"\"", code: \$source }" | gzip
  done
' sh {} + > /mnt/test.jsonl.gz
echo "    + Created!"

echo "  - Creating 'train.jsonl.gz'..."
find /tmp/*/training -type f -exec sh -c '
  for file do
    /jq -nc --rawfile source "${file}" "{ granularity: "\""file"\"", language: "\""java"\"", code: \$source }" | gzip
  done
' sh {} + > /mnt/train.jsonl.gz
echo "    + Created!"

echo "  - Creating 'valid.jsonl.gz'..."
find /tmp/*/validation -type f -exec sh -c '
  for file do
    /jq -nc --rawfile source "${file}" "{ granularity: "\""file"\"", language: "\""java"\"", code: \$source }" | gzip
  done
' sh {} + > /mnt/valid.jsonl.gz
echo "    + Created!"

echo "  + Dataset created!"
