.PHONY: deploy-global-s3

deploy-global-s3:
	cd global/s3 && terraform init && terraform apply -auto-approve