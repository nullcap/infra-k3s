#!/bin/bash

# FluxCD Cleanup Script
# This script removes FluxCD components after ArgoCD migration is complete

set -e

echo "🧹 Starting FluxCD cleanup..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "⚠️  WARNING: This will remove all FluxCD components!"
echo "   Make sure ArgoCD is working properly before proceeding."
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🗑️  Removing FluxCD components..."

# Remove FluxCD system namespace
echo "   Removing flux-system namespace..."
kubectl delete namespace flux-system --ignore-not-found=true

# Remove FluxCD CRDs
echo "   Removing FluxCD CRDs..."
kubectl delete crd gitrepositories.source.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd helmrepositories.source.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd helmcharts.source.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd helmreleases.helm.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd kustomizations.kustomize.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd alerts.notification.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd providers.notification.toolkit.fluxcd.io --ignore-not-found=true
kubectl delete crd receivers.notification.toolkit.fluxcd.io --ignore-not-found=true

echo "✅ FluxCD cleanup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Verify all applications are working in ArgoCD UI"
echo "2. Update any external references to FluxCD"
echo "3. Consider removing the backup directory if everything is working"
