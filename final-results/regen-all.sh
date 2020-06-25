#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

rm -f "${DIR}/finalized/*.csv"

"${DIR}/make-csvs-seq2seq.sh" | grep -v MISSING > "${DIR}/finalized/table-seq2seq.csv"
"${DIR}/make-csvs-code2seq.sh" | grep -v MISSING > "${DIR}/finalized/table-code2seq.csv"

cat "${DIR}/finalized/table-seq2seq.csv" | grep -v MISSING | python3 "${DIR}/gen-graphs.py" > "${DIR}/finalized/graph-seq2seq.csv"
cat "${DIR}/finalized/table-code2seq.csv" | grep -v MISSING | python3 "${DIR}/gen-graphs.py" > "${DIR}/finalized/graph-code2seq.csv"

"${DIR}/extract-single-attacks.sh" > "${DIR}/finalized/individual-attacks.csv"
