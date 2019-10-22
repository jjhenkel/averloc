#!/bin/bash

pushd ./temp

while read url
do
  git clone --depth 1 "$url"
done < "${1:-/dev/stdin}"

popd
