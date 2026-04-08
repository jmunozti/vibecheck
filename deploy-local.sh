#!/bin/bash
# deploy-local.sh — Deploy vibecheck on a local Kind cluster with Terraform
set -euo pipefail

echo "Starting vibecheck local deployment..."

# 1. Check dependencies
for cmd in docker kind kubectl terraform; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is not installed."
    exit 1
  fi
done
echo "Dependencies OK"

# 2. Validate structure
for dir in api web terraform; do
  [ -d "$dir" ] || { echo "Error: $dir/ directory not found"; exit 1; }
done

# 3. Create .env files from examples if they don't exist
for dir in api web terraform; do
  if [ ! -f "$dir/.env" ] && [ -f "$dir/.env-example" ]; then
    cp "$dir/.env-example" "$dir/.env"
    echo "Created $dir/.env from example"
  fi
done

# 4. Kind cluster config
cat > kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v1.29.0
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
      - containerPort: 30501
        hostPort: 30501
        protocol: TCP
      - containerPort: 30030
        hostPort: 30030
        protocol: TCP
EOF

# 5. Build Docker images
echo "Building Docker images..."
docker build -t vibecheck-api:latest api/ --no-cache
docker build -t vibecheck-web:latest web/ --no-cache
echo "Images built"

# 6. Create or recreate cluster
CLUSTER_NAME="vibecheck-cluster"
KUBECONFIG_FILE="kubeconfig-kind"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Deleting existing cluster..."
  kind delete cluster --name "${CLUSTER_NAME}"
fi

echo "Creating Kind cluster..."
kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml

# 7. Load images
echo "Loading images into cluster..."
kind load docker-image vibecheck-api:latest --name "${CLUSTER_NAME}"
kind load docker-image vibecheck-web:latest --name "${CLUSTER_NAME}"

# 8. Export kubeconfig
kind get kubeconfig --name "${CLUSTER_NAME}" > "${KUBECONFIG_FILE}"

# 9. Terraform apply
echo "Applying Terraform..."
cd terraform
export KUBECONFIG="../${KUBECONFIG_FILE}"
terraform init -upgrade
terraform apply -auto-approve

echo ""
echo "vibecheck deployed successfully!"
echo ""
echo "  Web UI:   http://localhost:30080"
echo "  API:      http://localhost:30501"
echo "  Grafana:  http://localhost:30030"
