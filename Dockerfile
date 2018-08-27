FROM k8s.gcr.io/debian-base-amd64:0.3.2

ARG KUBE_VERSION=v1.11.0
ARG DUMB_INIT_VERSION=1.2.1

COPY patches /patches

RUN set -ex && \
    apt-get update && \
    apt-get install -y curl git patch && \
    # Install kubectl command
    curl -s -LO https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    ./kubectl version --client && \
    # Install dumb-init
    curl -s -L -o /dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 && \
    chmod +x /dumb-init && \
    # Clone the Kubernetes repository
    git clone --depth 1 -b "$KUBE_VERSION" https://github.com/kubernetes/kubernetes.git && \
    cd kubernetes && git --no-pager log && \
    for file in $(ls -d /patches/*); do patch -p1 <$file; done && \
    git diff && \
    rm -rf /var/lib/apt/lists/*

FROM golang:1.10

COPY . /go/src/app/

RUN set -ex && \
    cd /go/src/app && \
    make build && \
    mv bin/kput /kput

FROM k8s.gcr.io/debian-base-amd64:0.3

RUN set -ex && \
    apt-get update && \
    apt-get install -y bash jq gawk && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

COPY --from=0 /kubectl /usr/local/bin/
COPY --from=0 /dumb-init /usr/local/bin/
COPY --from=0 /kubernetes/cluster/update-storage-objects.sh kubernetes/cluster/
COPY --from=0 /kubernetes/hack/lib kubernetes/hack/lib/
COPY --from=1 /kput /usr/local/bin/

RUN set -ex && \
    mkdir -p /kubernetes/_output/local/bin/linux/amd64 && \
    ln -s /usr/local/bin/kubectl /kubernetes/_output/local/bin/linux/amd64/kubectl

WORKDIR /kubernetes

ENTRYPOINT ["dumb-init", "/entrypoint.sh"]
CMD ["cluster/update-storage-objects.sh"]
