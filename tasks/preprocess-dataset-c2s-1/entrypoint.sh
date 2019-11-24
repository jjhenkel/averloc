#!/bin/bash

mkdir -p /mnt/outputs/test
mkdir -p /mnt/outputs/train
mkdir -p /mnt/outputs/valid

mkdir -p /tmp/java
mkdir -p /tmp/python

/astminer/gradlew processMyExample --args="/mnt/inputs/test.jsonl.gz"
mv -T "/tmp/${1}" /mnt/outputs/test

/astminer/gradlew processMyExample --args="/mnt/inputs/train.jsonl.gz"
mv -T "/tmp/${1}" /mnt/outputs/train

/astminer/gradlew processMyExample --args="/mnt/inputs/valid.jsonl.gz"
mv -T "/tmp/${1}" /mnt/outputs/valid
