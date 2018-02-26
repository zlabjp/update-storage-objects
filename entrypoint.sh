#!/bin/bash

set -e -o pipefail

if [[ -n "$DEBUG" ]]; then
  exec bash -x "$@"
fi

exec "$@"
