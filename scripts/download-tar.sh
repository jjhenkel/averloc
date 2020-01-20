#!/bin/bash

curl --progress-bar "${1}" \
2> >(
  tr "\n" "\0" \
  | tr "\r" "\n" \
  | sed "s/^/$(printf "\r\033[37m[DBG]:\033[0m   > ")/" \
  | tr -d "\n" \
  | tr "\0" "\n" \
  >&2
) | tar -xz -C "${2}"
