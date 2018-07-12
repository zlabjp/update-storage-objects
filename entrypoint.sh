#!/bin/bash

set -e -o pipefail

KUBE_VERSION="$(kubectl version -o json | jq -r '.serverVersion | .major+"."+.minor' | awk -F. '{printf "%2d%02d",$1,$2}')"
KUBE_VERSION_1_11="111"

# Apply workaround if k8s version is lower than 1.11.
if [[ $KUBE_VERSION -lt $KUBE_VERSION_1_11 ]]; then
  if [[ "$(kubectl get clusterrolebinding system:node -o="go-template={{.subjects}}")" == "<no value>" ]]; then
    echo "Deleting clusterrolebinding/system:node. This is a workaround for https://github.com/kubernetes/kubernetes/pull/60741."
    kubectl delete clusterrolebinding system:node
  fi
fi

if [[ -n "$DEBUG" ]]; then
  exec bash -x "$@"
fi

exec "$@"
