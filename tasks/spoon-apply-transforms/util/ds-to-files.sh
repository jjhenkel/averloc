#!/bin/bash

set -ex

rm -rf /tmp
mkdir /tmp

cat /mnt/inputs/${1}.targets.histo.txt > /histo.txt

xargs -P "$(nproc)" -d $'\n' -n 1 bash -c '
  THE_HASH="$(jq -r .sha256_hash)"
  jq -r .source_code <<< "${1}" | \
    sed -e "s/class WRAPPER {/class WRAPPER_${THE_HASH} {/g" \
  > "/tmp/${THE_HASH}.java"
' _ < <(cat /mnt/inputs/${1}.jsonl.gz | gzip -cd)
