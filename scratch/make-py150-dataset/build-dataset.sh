#!/bin/bash

# cat /app/files.test.txt | tr '\n' '\0' | xargs -0 -n1 -I{} sh -c '
#   /app/jq -nc --rawfile source "{}" "{ granularity: "\""file"\"", language: "\""python"\"", code: \$source }" | gzip
# ' > /mnt/test.jsonl.gz

cat /app/files.train.txt | tr '\n' '\0' | xargs -0 -n1 -I{} sh -c '
  /app/jq -nc --rawfile source "{}" "{ granularity: "\""file"\"", language: "\""python"\"", code: \$source }" | gzip
' > /mnt/train.jsonl.gz

cat /app/files.valid.txt | tr '\n' '\0' | xargs -0 -n1 -I{} sh -c '
  /app/jq -nc --rawfile source "{}" "{ granularity: "\""file"\"", language: "\""python"\"", code: \$source }" | gzip
' > /mnt/valid.jsonl.gz
