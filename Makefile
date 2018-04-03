build: $(shell find cmd/kput -name '*.go') $(shell find vendor -name '*.go')
	@CGO_ENABLED=0 go build -a -installsuffix cgo -o bin/kput ./cmd/kput

.PHONY: build-image
build-image:
	@docker run -v $(shell pwd):/go/src/app -w /go/src/app golang:1.10 make build

.PHONY: clean
clean:
	@rm -rf $(BIN_DIR)

DOCKER_IMAGE=zlabjp/update-storage-objects
.PHONY: docker-image
docker-image:
	@docker build --build-arg=KUBE_VERSION=$(KUBE_VERSION) -t $(DOCKER_IMAGE) .

CONCOURSE_PROJECT=update-storage-objects
.PHONY: set-pipeline
set-pipeline:
	@fly -t cs set-pipeline -p $(CONCOURSE_PROJECT) -c ci/pipeline.yml -l ci/credentials.yml

ci/pipeline.yml: ci/pipeline.yml.erb
	@erb -r date $< > $@
