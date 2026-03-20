#!/usr/bin/env bash
# bootstrap.sh — Run after terraform apply to apply manifests and install ingress-nginx
# Usage: ./scripts/bootstrap.sh <resource-group> <cluster-name>

set -euo pipefail

RG=${1:?"Usage: $0 <resource-group> <cluster-name>"}
CLUSTER=${2:?"Usage: $0 <resource-group> <cluster-name>"}

echo "==> Getting AKS credentials for $CLUSTER in $RG"
az aks get-credentials --resource-group "$RG" --name "$CLUSTER" --overwrite-existing

echo "==> Verifying cluster access"
kubectl get nodes

echo "==> Applying RBAC manifests"
kubectl apply -f manifests/rbac/rbac.yaml

echo "==> Applying network policies"
kubectl apply -f manifests/network-policies/network-policies.yaml

echo "==> Adding ingress-nginx Helm repo"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "==> Installing ingress-nginx"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --wait

echo "==> Adding cert-manager Helm repo"
helm repo add jetstack https://charts.jetstack.io
helm repo update

echo "==> Installing cert-manager"
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --wait

echo "==> Cluster bootstrap complete!"
kubectl get pods -A
