#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error(){ echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo ""
echo "🚀 Local Kubernetes Monitoring Stack — Setup"
echo "============================================="
echo ""

# 1. DEPENDENCIES
log "Checking dependencies..."
command -v docker  &>/dev/null || error "Docker not found. Install Docker Desktop."
command -v kind    &>/dev/null || error "Kind not found.    Run: brew install kind"
command -v kubectl &>/dev/null || error "kubectl not found. Run: brew install kubectl"
command -v helm    &>/dev/null || error "Helm not found.    Run: brew install helm"
log "All dependencies found."

# 2. CLUSTER
log "Creating Kind cluster..."
if kind get clusters | grep -q "^kind$"; then
  warn "Cluster 'kind' already exists. Skipping."
else
  kind create cluster --config kind-config.yaml
  log "Cluster created."
fi

# 3. BUILD & LOAD IMAGE
log "Building Docker image..."
docker build -t k8s-monitoring/api:v1.0.0 .
log "Loading image into Kind..."
kind load docker-image k8s-monitoring/api:v1.0.0

# 4. NAMESPACES
log "Creating namespaces..."
kubectl create namespace dev  --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

# 5. APP
log "Deploying application..."
kubectl apply -f k8s/dev/
kubectl apply -f k8s/prod/

# 6. NGINX INGRESS
log "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
log "Waiting for Ingress Controller to be ready..."
sleep 10
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 7. POSTGRESQL
log "Adding Bitnami Helm repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami &>/dev/null
helm repo update &>/dev/null

log "Installing PostgreSQL in dev..."
if helm status postgres-dev -n dev &>/dev/null; then
  warn "postgres-dev already installed. Skipping."
else
  helm install postgres-dev bitnami/postgresql \
    --namespace dev \
    --set auth.username=kbs-admin \
    --set auth.password=password-123 \
    --set auth.postgresPassword=password-123 \
    --set auth.database=my-db \
    --set primary.persistence.size=1Gi
fi

log "Installing PostgreSQL in prod..."
if helm status postgres-prod -n prod &>/dev/null; then
  warn "postgres-prod already installed. Skipping."
else
  helm install postgres-prod bitnami/postgresql \
    --namespace prod \
    --set auth.username=kbs-admin \
    --set auth.password=prod-password-456 \
    --set auth.postgresPassword=prod-password-456 \
    --set auth.database=my-db \
    --set primary.persistence.size=2Gi
fi

# 8. PROMETHEUS + GRAFANA
log "Adding Prometheus Community Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &>/dev/null
helm repo update &>/dev/null

log "Installing kube-prometheus-stack..."
if helm status monitoring -n monitoring &>/dev/null; then
  warn "monitoring stack already installed. Skipping."
else
  helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.service.type=ClusterIP
fi

log "Applying Grafana Ingress..."
kubectl apply -f k8s/monitoring/grafana-ingress.yaml

# 9. DNS
if ! grep -q "dev.local" /etc/hosts; then
  warn "Adding DNS entries to /etc/hosts (requires sudo)..."
  echo "127.0.0.1 dev.local prod.local grafana.local" | sudo tee -a /etc/hosts
else
  warn "DNS entries already in /etc/hosts. Skipping."
fi

# DONE
GRAFANA_PASS=$(kubectl --namespace monitoring get secrets monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d)

echo ""
echo "============================================="
echo -e "${GREEN}✅ Setup complete!${NC}"
echo "============================================="
echo ""
echo "  API (dev)     →  http://dev.local"
echo "  API (prod)    →  http://prod.local"
echo "  Grafana       →  http://grafana.local"
echo "  Grafana user  →  admin"
echo "  Grafana pass  →  $GRAFANA_PASS"
echo ""
