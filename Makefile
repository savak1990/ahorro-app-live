.PHONY: deploy-global-s3

deploy-global-s3:
	cd live/global/s3 && terraform init && terraform apply -auto-approve

deploy-global-iam:
	cd live/global/iam && terraform init && terraform apply -auto-approve

deploy-global-s3-artifacts:
	cd live/global/s3-artifacts && terraform init && terraform apply -auto-approve

deploy-global-cert: deploy-global-s3
	cd live/global/certificate && terraform init && terraform apply -auto-approve

deploy-stable-cognito:
	cd live/stable/cognito && terraform init && terraform apply -auto-approve

deploy-stable-transactions-service-db:
	cd live/stable/transactions-service/db && terraform init && terraform apply -auto-approve

deploy-stable-transactions-service:
	cd live/stable/transactions-service/service && terraform init && terraform apply -auto-approve
