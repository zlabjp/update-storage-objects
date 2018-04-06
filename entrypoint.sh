#!/bin/bash

set -e -o pipefail

if [[ "$(kubectl get clusterrolebinding system:node -o="go-template={{.subjects}}")" == "<no value>" ]]; then
  echo "Deleting clusterrolebinding/system:node. This is a workaround for https://github.com/kubernetes/kubernetes/pull/60741."
  kubectl delete clusterrolebinding system:node
fi

if [[ -n "$DEBUG" ]]; then
  exec bash -x "$@"
fi

exec "$@"
