ARG DEBIAN_BASE_VERSION=1.0.0

FROM k8s.gcr.io/debian-base-amd64:${DEBIAN_BASE_VERSION} AS stage-0
ENV KUBE_VERSION=v1.16.0
RUN set -ex && \
    apt-get update && \
    apt-get install -y curl git patch

FROM stage-0 AS kubectl
RUN set -ex && \
    # Install kubectl command
    curl -s -L -o /kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /kubectl && \
    /kubectl version --client

FROM stage-0 AS dumb-init
ARG DUMB_INIT_VERSION=1.2.2
RUN set -ex && \
    # Install dumb-init
    curl -s -L -o /dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 && \
    chmod +x /dumb-init

FROM stage-0 AS update-storage-objects
COPY patches /patches
RUN set -ex && \
    # Clone the Kubernetes repository
    git clone --depth 1 -b "$KUBE_VERSION" https://github.com/kubernetes/kubernetes.git && \
    cd kubernetes && git --no-pager log && \
    for file in $(ls -d /patches/*); do patch -p1 <$file; done && \
    git diff

FROM golang:1.12 AS kput
COPY . /go/src/app/
RUN set -ex && \
    cd /go/src/app && \
    make build && \
    mv bin/kput /kput

FROM k8s.gcr.io/debian-base-amd64:${DEBIAN_BASE_VERSION}

RUN set -ex && \
    apt-get update && \
    apt-get install -y bash jq gawk && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

COPY --from=kubectl /kubectl /usr/local/bin/
COPY --from=dumb-init /dumb-init /usr/local/bin/
COPY --from=update-storage-objects /kubernetes/cluster/update-storage-objects.sh kubernetes/cluster/
COPY --from=update-storage-objects /kubernetes/hack/lib kubernetes/hack/lib/
COPY --from=kput /kput /usr/local/bin/

RUN set -ex && \
    mkdir -p /kubernetes/_output/local/bin/linux/amd64 && \
    ln -s /usr/local/bin/kubectl /kubernetes/_output/local/bin/linux/amd64/kubectl

WORKDIR /kubernetes

ENTRYPOINT ["dumb-init", "/entrypoint.sh"]
CMD ["cluster/update-storage-objects.sh"]
