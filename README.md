# Kubernetes: update-storage-objects Docker Image

[![Build Status](https://travis-ci.org/zlabjp/update-storage-objects.svg?branch=master)](https://travis-ci.org/zlabjp/update-storage-objects)

The easiest way to run `cluster/update-storage-objects.sh`.

## What is `cluster/update-storage-objects.sh`?

[`cluster/update-storage-objects.sh`](https://github.com/kubernetes/kubernetes/blob/master/cluster/update-storage-objects.sh) is the script file to update existing objects in the storage (etcd) to new version.

Steps to use that script to upgrade the cluster to a new version: https://kubernetes.io/docs/tasks/administer-cluster/cluster-management/#upgrading-to-a-different-api-version

## What is update-storage-objects Docker Image?

update-storage-objects is a container image which contains patched `cluster/update-storage-objects.sh` and `kubectl` command.

**Note that the below patches have been applied to the `cluster/update-storage-objects.sh` in the container image. Please see the details before using.**

1. [`patches/59403.patch`](./patches/59403.patch): Remove `endpoints` resource from list of resources to be updated. (https://github.com/kubernetes/kubernetes/issues/59403)
2. [`patches/60970.patch`](./patches/60970.patch): Use [`kput` command](./cmd/kput) for updating existing objects instead of `kubectl replace` command. (https://github.com/kubernetes/kubernetes/issues/60970)
    - `kput` command just updates existing objects. Even if the `kubectl.kubernetes.io/last-applied-configuration` annotation existed, `kput` command keeps it as it is.
3. [`patches/add-skip-error-opition.patch`](./patches/add-skip-error-opition.patch): Add a option to skip errors in case of failing get or replace objects. This feature is available when set `SKIP_UPDATE_OBJECT_ERROR` environment variable with any values.

## How to use this image

You can run this image in your local environment:

```
docker run -v $HOME/.kube:/.kube -e KUBECONFIG=/.kube/config zlabjp/update-storage-objects:1.4.0
```

You can also run this image from inside your cluster:

```
kubectl apply -f https://raw.githubusercontent.com/zlabjp/update-storage-objects/master/deploy/update-storage-objects.yaml
```

## License

This software is released under the MIT License and includes the work that is distributed in the Apache License 2.0.
