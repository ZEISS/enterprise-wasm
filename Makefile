.PHONY: deploy-aks-spin-dapr-shared-dotnet
deploy-aks-spin-dapr-shared-dotnet:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-dotnet/ deploy-shared

.PHONY: deploy-aks-spin-dapr-sidecar-dotnet
deploy-aks-spin-dapr-sidecar-dotnet:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-dotnet/ deploy-sidecar

.PHONY: deploy-aks-spin-dapr-shared-rs
deploy-aks-spin-dapr-shared-shared-rs:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-rs/ deploy-shared

.PHONY: deploy-aks-spin-dapr-sidecar-rs
deploy-aks-spin-dapr-sidecar-rs:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-rs/ deploy-sidecar

.PHONY: deploy-aks-spin-dapr-shared-ts
deploy-aks-spin-dapr-shared-ts:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-ts/ deploy-shared

.PHONY: deploy-aks-spin-dapr-sidecar-ts
deploy-aks-spin-dapr-sidecar-ts:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-ts/ deploy-sidecar

.PHONY: deploy-aks-warp-dapr-shared-rs
deploy-aks-warp-dapr-shared-rs:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/warp-dapr-rs/ deploy-shared

.PHONY: destroy-aks-spin-dapr
destroy-aks-spin-dapr:
	$(MAKE) -C ./infra/aks-spin-dapr/ destroy

.PHONY: test-orders
test-orders:
	$(MAKE) -C ./helpers/orderdata-ts/ run-test
