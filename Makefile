.PHONY: deploy-aks-kn-dapr-express-ts
deploy-aks-kn-dapr-express-ts:
	$(MAKE) -C ./infra/aks-kn-dapr/ deploy
	$(MAKE) -C ./samples/express-dapr-ts/ deploy-shared

.PHONY: destroy-aks-spin-dapr
destroy-aks-spin-dapr:
	$(MAKE) -C ./infra/aks-spin-dapr/ destroy

.PHONY: destroy-aks-kn-dapr
destroy-aks-kn-dapr:
	$(MAKE) -C ./infra/aks-kn-dapr/ destroy

.PHONY: test-orders
test-orders:
	$(MAKE) -C ./helpers/orderdata-ts/ run-test
