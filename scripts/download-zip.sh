#!/bin/bash

TMPFILE=$(mktemp)
curl --progress-bar $1 -o "${TMPFILE}" \
2> >(
  tr "\n" "\0" \
  | tr "\r" "\n" \
  | sed "s/^/$(printf "\r\033[37m[DBG]:\033[0m   > ")/" \
  | tr -d "\n" \
  | tr "\0" "\n" \
  >&2
)
unzip -qq "${TMPFILE}" "${3}" -d "${2}"
rm "${TMPFILE}"
