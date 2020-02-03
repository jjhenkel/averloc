#!/bin/bash

trap "echo Exited!; exit 1;" SIGINT SIGTERM

javac -cp /app/spoon.jar:/app/gson.jar:/app/log4j-core.jar:/app/log4j-api.jar:/app transforms/*.java && \
  javac -cp /app/spoon.jar:/app/gson.jar:/app/log4j-core.jar:/app/log4j-api.jar:/app Transforms.java

java -XX:-UsePerfData -Xmx128g -d64 -cp /app/spoon.jar:/app/gson.jar:/app/log4j-core.jar:/app/log4j-api.jar:/app Transforms

echo "Starting normalizer:"
find /mnt/raw-outputs/ -mindepth 2 -maxdepth 2 -type d | \
    python3 /src/function-parser/function_parser/parser_cli.py java raw 
echo "  + Done!"
