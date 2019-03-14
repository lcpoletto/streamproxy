.terraform:
	terraform init

.PHONY: plan
plan: .terraform
	terraform plan

.PHONY: apply
start: .terraform
	@terraform apply --auto-approve
	@google-chrome-stable --disable-gpu-driver-bug-workarounds --proxy-server=http://$$(terraform output proxy_ip):8888

.PHONY: .terraform
stop:
	@terraform destroy --auto-approve
