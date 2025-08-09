#!/bin/bash

# ArgoCD Migration Script
# This script helps migrate from FluxCD to ArgoCD

set -e

echo "🚀 Starting ArgoCD Migration..."

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

echo "✅ Kubernetes cluster is accessible"

# Step 1: Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl apply -f argocd/install/argocd-namespace.yaml
kubectl apply -f argocd/install/argocd-install.yaml

echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || {
    echo "❌ ArgoCD failed to start within timeout"
    exit 1
}

echo "✅ ArgoCD is ready!"

# Step 2: Get admin password
echo "🔑 ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# Step 3: Apply Helm repositories
echo "📚 Applying Helm repositories..."
kubectl apply -f argocd/helm-repositories/

# Step 4: Deploy root application
echo "🌳 Deploying root application..."
kubectl apply -f argocd/root-app.yaml

echo "✅ Migration setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Login with admin and the password shown above"
echo "3. Monitor application sync status in the UI"
echo "4. Once everything is working, you can remove FluxCD with: ./cleanup-flux.sh"
echo ""
echo "🔗 ArgoCD UI will be available at: https://localhost:8080"
echo "   (accept the self-signed certificate)"
