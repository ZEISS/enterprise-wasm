.PHONY: deploy-aks-spin-dapr-rs
deploy-aks-spin-dapr-rs:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-rs/ deploy-shared

.PHONY: destroy-aks-spin-dapr-rs
destroy-aks-spin-dapr-rs: destroy-aks-spin-dapr

.PHONY: deploy-aks-spin-dapr-ts
deploy-aks-spin-dapr-ts:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-ts/ deploy-shared

.PHONY: destroy-aks-spin-dapr-ts
destroy-aks-spin-dapr-ts: destroy-aks-spin-dapr

.PHONY: destroy-aks-spin-dapr
destroy-aks-spin-dapr:
	$(MAKE) -C ./infra/aks-spin-dapr/ destroy

.PHONY: test-orders
test-orders:
	$(MAKE) -C ./helpers/orderdata-ts/ run-test
