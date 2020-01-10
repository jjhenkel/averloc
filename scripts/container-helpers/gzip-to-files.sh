#!/bin/bash

THE_LINE="$(</dev/stdin)"
HAS_SOURCE_CODE_KEY="$(jq 'has("source_code")' <<< "${THE_LINE}")"

if [ "$HAS_SOURCE_CODE_KEY" == "false" ]; then
    THE_HASH="$(jq -r .code <<< "${THE_LINE}" | sha256sum | awk '{ print $1 }')"
    jq -r .code <<< "${THE_LINE}" \
        > /mnt/outputs/${THE_HASH}.java 
else
    THE_HASH="$(jq -r .sha256_hash <<< "${THE_LINE}")"
    jq -r .source_code <<< "${THE_LINE}" \
        > /mnt/outputs/${THE_HASH}.java 
fi
