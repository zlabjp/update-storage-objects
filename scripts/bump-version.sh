#!/usr/bin/env bash

set -e -o pipefail

image="zlabjp/update-storage-objects"
version="$1"

if [[ -z "$version" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

for file in README.md $(ls -d deploy/*.yaml); do
  sed -i"" -e "s|${image}:.*|${image}:${version}|g" "$file"
done

git --no-pager diff -u
