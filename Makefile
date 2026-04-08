.PHONY: deploy clean status test lint

# Deploy everything locally with Kind + Terraform
deploy:
	chmod +x deploy-local.sh
	./deploy-local.sh

# Check cluster status
status:
	kubectl --kubeconfig kubeconfig-kind get all -n vibecheck

# Run backend tests
test:
	cd backend && poetry run pytest tests/ -v

# Lint backend code
lint:
	cd backend && poetry run ruff check .

# Destroy cluster
clean:
	kind delete cluster --name vibecheck-cluster
	rm -f kubeconfig-kind kind-config.yaml
