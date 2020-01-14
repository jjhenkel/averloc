#!/bin/bash

INPUT_DIR=/mnt/inputs
OUTPUT_DIR=/mnt/outputs

echo "Starting dataset normalization..."

mkdir -p "${OUTPUT_DIR}"

python3 /src/function-parser/function_parser/parser_cli.py "${1}" "${2}"

echo "  + Dataset normalization complete!"
