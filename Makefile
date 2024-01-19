.PHONY: deploy-aks-spin-dapr-rs
deploy-aks-spin-dapr-rs:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-rs/ deploy-shared

.PHONY: deploy-aks-spin-dapr-ts
deploy-aks-spin-dapr-ts:
	$(MAKE) -C ./infra/aks-spin-dapr/ deploy
	$(MAKE) -C ./samples/spin-dapr-ts/ deploy-shared

