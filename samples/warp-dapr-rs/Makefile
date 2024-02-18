.PHONY: build
build:
	./build.sh

.PHONY: deploy-shared
deploy-shared: build
	./deploy.sh shared

.PHONY: destroy-shared
destroy-shared:
	kubectl delete -f ./workload-aks-shared.yml
	helm uninstall receiver-standard-dapr receiver-express-dapr distributor-dapr

.PHONY: deploy-sidecar
deploy-sidecar: build
	./deploy.sh sidecar

.PHONY: destroy-sidecar
destroy-sidecar:
	kubectl delete -f ./workload-aks-sidecar.yml
