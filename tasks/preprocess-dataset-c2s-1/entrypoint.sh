#!/bin/bash

# Need to modify Java to read in X.jsonl.gz files
/astminer/gradlew processMyExample --args="/mnt/inputs/test.jsonl.gz"
/astminer/gradlew processMyExample --args="/mnt/inputs/train.jsonl.gz"
/astminer/gradlew processMyExample --args="/mnt/inputs/valid.jsonl.gz"
