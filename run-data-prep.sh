 #!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker build \
  -t "adv-ml-project/data-prep-python:$(git rev-parse HEAD)" \
  -f "${DIR}/data-prep/python/Dockerfile" \
  "${DIR}/data-prep/python" \
&> /dev/null

docker run \
  -i \
  --rm \
  -v `pwd`:/mnt \
  "adv-ml-project/data-prep-python:$(git rev-parse HEAD)" \
    parse-directory /mnt/data-prep/python/temp
