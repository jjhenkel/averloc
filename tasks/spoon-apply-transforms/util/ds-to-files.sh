#!/bin/bash

set -ex

rm -rf /tmp
mkdir /tmp

cat /mnt/inputs/${1}.targets.histo.txt > /histo.txt

cat /mnt/inputs/${1}.jsonl.gz \
  | gzip -cd \
  | parallel --pipe -N1 --will-cite "
    jq -r .source_code \
      | sed -e \"s/class WRAPPER {/class WRAPPER_\${THE_HASH} {/g\" \
    > \$(mktemp).java
  "
