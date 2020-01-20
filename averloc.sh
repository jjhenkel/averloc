#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SHORT_NAME="$(basename ${0})"

if [ "${1}" == "gzip-to-files" ]; then
    echo "[${SHORT_NAME}] Running gzip-to-files on ${2}"
    echo "[${SHORT_NAME}]   - Entering directory: $(dirname ${2})"
    pushd "$(dirname "${2}")" > /dev/null
    echo "[${SHORT_NAME}]   - Running script..."
    cat "${DIR}/${2}" | "${DIR}/scripts/gzip-to-files.sh" "$(basename "${2}" .jsonl.gz)" 
    popd > /dev/null
    echo "[${SHORT_NAME}]   + Done!"
else
    echo "[${SHORT_NAME}] Please provide a valid command as the first argument to this script."
fi
