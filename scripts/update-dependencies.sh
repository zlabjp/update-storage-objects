#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

dependencies=(
  "github.com/spf13/cobra@v0.0.5" \
  "k8s.io/apimachinery@v0.17.0" \
  "k8s.io/cli-runtime@v0.17.0" \
  "k8s.io/client-go@v0.17.0" \
  "k8s.io/component-base@v0.17.0" \
  "k8s.io/kubectl@v0.17.0" \
)

GO111MODULE=on go get "${dependencies[@]}"
