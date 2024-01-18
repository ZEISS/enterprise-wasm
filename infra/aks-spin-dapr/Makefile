.PHONY: destroy
destroy:
	terraform apply --destroy

.PHONY: deploy
deploy:
	terraform apply --auto-approve
	./prepare-cluster.sh
