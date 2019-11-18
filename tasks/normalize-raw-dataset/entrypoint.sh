#!/bin/bash

INPUT_DIR=/mnt/inputs
OUTPUT_DIR=/mnt/outputs

mkdir -p "${OUTPUT_DIR}"

# Process python
echo "Normalizing python files..."
find "${INPUT_DIR}" -type f -name "*.py" \
  | parallel --bar --will-cite python3 /src/function-parser/function_parser/parser_cli.py \
      --language python {} 
echo "  + Complete!"

# Process java
echo "Normalizing java files..."
find "${INPUT_DIR}" -type f -name "*.java" \
  | parallel --bar --will-cite python3 /src/function-parser/function_parser/parser_cli.py \
      --language java {}
echo "  + Complete!"
