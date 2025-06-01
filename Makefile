.PHONY: deploy-stable

deploy-stable:
	cd stable && terraform apply -auto-approve