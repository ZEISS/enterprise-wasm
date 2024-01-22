.PHONY: deploy-aks-spin-dapr-shared-rs
deploy-aks-spin-dapr-shared-rs:
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

.PHONY: destroy-aks-spin-dapr-rs
destroy-aks-spin-dapr-rs: destroy-aks-spin-dapr

.PHONY: destroy-aks-spin-dapr-ts
destroy-aks-spin-dapr-ts: destroy-aks-spin-dapr

.PHONY: destroy-aks-spin-dapr
destroy-aks-spin-dapr:
	$(MAKE) -C ./infra/aks-spin-dapr/ destroy

.PHONY: test-orders
test-orders:
	$(MAKE) -C ./helpers/orderdata-ts/ run-test
