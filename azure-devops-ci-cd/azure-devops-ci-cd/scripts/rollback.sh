#!/usr/bin/env bash
# rollback.sh — Roll back a Helm release to the previous revision
# Usage: ./scripts/rollback.sh <release-name> <namespace> [revision]

set -euo pipefail

RELEASE="${1:?Usage: $0 <release-name> <namespace> [revision]}"
NAMESPACE="${2:?Usage: $0 <release-name> <namespace> [revision]}"
REVISION="${3:-0}"   # 0 = previous revision

echo "==> Rolling back $RELEASE in namespace $NAMESPACE"

echo "Current history:"
helm history "$RELEASE" -n "$NAMESPACE" --max 5

if [ "$REVISION" = "0" ]; then
  echo "==> Rolling back to previous revision"
  helm rollback "$RELEASE" --namespace "$NAMESPACE" --wait --timeout 3m
else
  echo "==> Rolling back to revision $REVISION"
  helm rollback "$RELEASE" "$REVISION" --namespace "$NAMESPACE" --wait --timeout 3m
fi

echo ""
echo "Post-rollback status:"
helm status "$RELEASE" -n "$NAMESPACE"

echo ""
echo "Pod status:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"

echo ""
echo "Rollback complete."
