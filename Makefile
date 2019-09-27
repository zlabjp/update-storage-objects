build:
	@GO111MODULE=on CGO_ENABLED=0 go build -a -installsuffix cgo -o bin/kput ./cmd/kput

.PHONY: build-image
build-image:
	@docker run -v $(shell pwd):/go/src/app -v "$${GOPATH}/pkg/mod:/go/pkg/mod" -w /go/src/app golang:1.12 make build

.PHONY: clean
clean:
	@rm -rf $(BIN_DIR)

DOCKER_IMAGE=zlabjp/update-storage-objects
.PHONY: docker-image
docker-image:
	@DOCKER_BUILDKIT=1 docker build -t $(DOCKER_IMAGE) .
