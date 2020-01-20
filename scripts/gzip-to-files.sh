#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SHORT_NAME="$(basename ${0})"

echo "[${SHORT_NAME}] Building script host container..."
docker build -t "$(whoami)/averloc:scripts-host" "${DIR}" > /dev/null
echo "[${SHORT_NAME}]   + Done!"

echo "[${SHORT_NAME}] Clearing out directory $(pwd)/${1}..."
docker run --rm -v "$(pwd):/mnt/outputs" "$(whoami)/averloc:scripts-host" \
    rm -rf "/mnt/outputs/${1}"
echo "[${SHORT_NAME}]   + Cleared!"

echo "[${SHORT_NAME}] Generating files (this might take a moment)..."
gzip -cd | \
docker run -i --rm  -v "$(pwd)/${1}:/mnt/outputs" "$(whoami)/averloc:scripts-host" \
    parallel --blocksize 5M --pipe -N1 --will-cite bash /helpers/gzip-to-files.sh
echo "[${SHORT_NAME}]   + Generated $(find $(pwd)/${1} -type f -name "*.java" | wc -l) files"
