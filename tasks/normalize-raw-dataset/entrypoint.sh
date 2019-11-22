#!/bin/bash

INPUT_DIR=/mnt/inputs
OUTPUT_DIR=/mnt/outputs

echo "Starting dataset normalization..."

mkdir -p "${OUTPUT_DIR}"

echo "  - Normalizing 'test.jsonl.gz'..."
cat /mnt/inputs/test.jsonl.gz \
  | gzip -cd \
  | python3 /src/function-parser/function_parser/parser_cli.py \
  | gzip \
> /mnt/outputs/test.jsonl.gz
echo "    + Normalized!"

echo "  - Normalizing 'train.jsonl.gz'..."
cat /mnt/inputs/train.jsonl.gz \
  | gzip -cd \
  | python3 /src/function-parser/function_parser/parser_cli.py \
  | gzip \
> /mnt/outputs/train.jsonl.gz
echo "    + Normalized!"

echo "  - Normalizing 'valid.jsonl.gz'..."
cat /mnt/inputs/valid.jsonl.gz \
  | gzip -cd \
  | python3 /src/function-parser/function_parser/parser_cli.py \
  | gzip \
> /mnt/outputs/valid.jsonl.gz
echo "    + Normalized!"

echo "  + Dataset normalization complete!"
