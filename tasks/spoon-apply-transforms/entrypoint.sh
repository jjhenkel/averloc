#!/bin/bash


trap "echo Exited!; exit 1;" SIGINT SIGTERM

java -XX:-UsePerfData -Xmx128g -d64 -cp /app/spoon.jar:/app/gson.jar:/app Transforms
