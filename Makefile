.PHONY: deploy clean status

# Deploy everything locally with Kind + Terraform
deploy:
	chmod +x deploy-local.sh
	./deploy-local.sh

# Check cluster status
status:
	kubectl --kubeconfig kubeconfig-kind get all -n vibecheck

# Destroy cluster
clean:
	kind delete cluster --name vibecheck-cluster
	rm -f kubeconfig-kind kind-config.yaml
