.PHONY: destroy
destroy:
	terraform apply --destroy

.PHONY: destroy-approved
destroy-approved:
	terraform apply --destroy --auto-approve

.PHONY: deploy
deploy:
	terraform apply --auto-approve
	./prepare-cluster.sh
