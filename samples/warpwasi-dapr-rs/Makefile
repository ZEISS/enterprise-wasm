REPO_ROOT := $(shell git rev-parse --show-toplevel)

.PHONY: common
common:
	${REPO_ROOT}/helpers/common.sh

.PHONY: build
build:
	./build.sh

.PHONY: deploy-shared
deploy-shared: build
	./deploy.sh shared

.PHONY: destroy-shared
destroy-shared:
	./destroy.sh shared

.PHONY: deploy-sidecar
deploy-sidecar: build
	./deploy.sh sidecar

.PHONY: destroy-sidecar
destroy-sidecar:
	./destroy.sh sidecar
