#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }

# Detect OS for sed compatibility
OS="$(uname -s)"

echo ""
echo "🗑️  Local Kubernetes Monitoring Stack — Delete"
echo "================================================="
echo ""

# 1. HELM RELEASES
log "Uninstalling Helm releases..."
helm uninstall monitoring    -n monitoring 2>/dev/null && log "monitoring uninstalled."   || warn "monitoring not found."
helm uninstall postgres-dev  -n dev        2>/dev/null && log "postgres-dev uninstalled." || warn "postgres-dev not found."
helm uninstall postgres-prod -n prod       2>/dev/null && log "postgres-prod uninstalled."|| warn "postgres-prod not found."

# 2. PVCs
log "Deleting PVCs..."
kubectl delete pvc -n dev  --all 2>/dev/null || warn "No PVCs in dev."
kubectl delete pvc -n prod --all 2>/dev/null || warn "No PVCs in prod."

# 3. NAMESPACES
log "Deleting namespaces..."
kubectl delete namespace dev           2>/dev/null && log "dev deleted."           || warn "dev not found."
kubectl delete namespace prod          2>/dev/null && log "prod deleted."          || warn "prod not found."
kubectl delete namespace monitoring    2>/dev/null && log "monitoring deleted."    || warn "monitoring not found."
kubectl delete namespace ingress-nginx 2>/dev/null && log "ingress-nginx deleted." || warn "ingress-nginx not found."

# 4. CLUSTER
log "Deleting Kind cluster..."
if kind get clusters | grep -q "^kind$"; then
  kind delete cluster
  log "Cluster deleted."
else
  warn "No Kind cluster found."
fi

# 5. DNS
log "Removing DNS entries from /etc/hosts..."
if grep -q "dev.local" /etc/hosts; then
  if [ "$OS" = "Darwin" ]; then
    sudo sed -i \'\' \'/dev\.local/d\' /etc/hosts
  else
    sudo sed -i \'/dev\.local/d\' /etc/hosts
  fi
  log "DNS entries removed."
else
  warn "No DNS entries found in /etc/hosts. Skipping."
fi

echo ""
echo "================================================="
echo -e "${GREEN}✅ Delete completed!${NC}"
echo "================================================="
echo ""
