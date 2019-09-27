#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

dependencies=(
  "github.com/spf13/cobra@v0.0.5" \
  "k8s.io/apimachinery@kubernetes-1.16.0" \
  "k8s.io/cli-runtime@kubernetes-1.16.0" \
  "k8s.io/client-go@kubernetes-1.16.0" \
  "k8s.io/component-base@kubernetes-1.16.0" \
  "k8s.io/kubectl@kubernetes-1.16.0" \
)

GO111MODULE=on go get "${dependencies[@]}"
