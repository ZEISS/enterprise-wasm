.PHONY: build
build:
	npm run build
	./build.sh

.PHONY: deploy-shared
deploy-shared: build
	./deploy.sh shared

.PHONY: destroy-shared-deploy
destroy-shared-deploy:
	kubectl delete -f ./workload-aks-shared-deploy.yml
	helm uninstall receiver-standard-dapr receiver-express-dapr distributor-dapr

.PHONY: destroy-shared-operator
destroy-shared-operator:
	kubectl delete -f ./workload-aks-shared-spinapps.yml
	helm uninstall receiver-standard-dapr receiver-express-dapr distributor-dapr

.PHONY: deploy-sidecar
deploy-sidecar: build
	./deploy.sh sidecar

.PHONY: destroy-sidecar
destroy-sidecar:
	kubectl delete -f ./workload-aks-sidecar.yml
