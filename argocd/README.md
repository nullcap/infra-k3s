# ArgoCD Migration

This directory contains the ArgoCD configuration for migrating from FluxCD to ArgoCD.

## Directory Structure

```
argocd/
├── install/
│   ├── argocd-namespace.yaml    # ArgoCD namespace
│   └── argocd-install.yaml      # ArgoCD installation Application
├── helm-repositories/
│   ├── grafana.yaml             # Grafana Helm repository
│   └── sealed-secrets.yaml     # Sealed Secrets Helm repository
├── applications/
│   ├── infrastructure.yaml     # Infrastructure components
│   ├── sealed-secrets.yaml     # Sealed Secrets controller
│   ├── grafana-k8s-monitoring.yaml  # Grafana Cloud monitoring
│   ├── loki-grafanacloud.yaml  # Loki/Promtail for Grafana Cloud
│   ├── archivetw.yaml          # Archive Team Warrior
│   └── monitoring-secrets.yaml # Monitoring secrets
├── manifests/
│   ├── infrastructure/         # Infrastructure manifests
│   ├── archivetw/             # Archive Team Warrior manifests
│   └── monitoring-secrets/    # Sealed secrets for monitoring
├── root-app.yaml              # Root Application of Applications
├── migrate.sh                 # Migration script
├── cleanup-flux.sh           # FluxCD cleanup script
└── README.md                 # This file
```

## Current Status

✅ **Completed:**
- ArgoCD directory structure created
- All applications converted from FluxCD to ArgoCD format
- Helm repositories configured
- Infrastructure manifests migrated
- Archive Team Warrior manifests created
- Monitoring secrets preserved

⚠️ **Needs Attention:**
- Grafana Cloud credentials need to be configured manually
- Loki Grafana Cloud credentials need to be updated
- Some complex Helm values simplified for ArgoCD compatibility

## Migration Steps

### 1. Install ArgoCD

```bash
# Apply ArgoCD namespace and installation
kubectl apply -f argocd/install/argocd-namespace.yaml
kubectl apply -f argocd/install/argocd-install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. Get ArgoCD Admin Password

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Access ArgoCD UI

```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Or use the ingress if Traefik is configured
# http://argocd.local (add to /etc/hosts if needed)
```

### 4. Apply Helm Repositories

```bash
# Apply Helm repository configs
kubectl apply -f argocd/helm-repositories/
```

### 5. Deploy Root Application

```bash
# Deploy the root application that manages all other applications
kubectl apply -f argocd/root-app.yaml
```

## Application Overview

### Infrastructure
- **Namespaces**: Core namespaces (monitoring, archivetw, etc.)
- **RBAC**: Prometheus adapter roles
- **Traefik**: Additional Traefik configuration

### Sealed Secrets
- **sealed-secrets**: Bitnami Sealed Secrets controller (deployed to flux-system namespace for compatibility)

### Monitoring
- **grafana-k8s-monitoring**: Grafana Cloud monitoring stack (simplified configuration)
- **loki-grafanacloud**: Loki stack with Promtail for log shipping to Grafana Cloud
- **monitoring-secrets**: Sealed secrets containing Grafana Cloud credentials

### Applications
- **archivetw**: Archive Team Warrior deployment

## Important Notes

### Grafana Cloud Configuration
The Grafana Cloud monitoring application has been simplified for ArgoCD compatibility. You'll need to:

1. **Update credentials manually** in the ArgoCD UI or via kubectl
2. **Configure external secrets** for the passwords
3. **Verify the monitoring stack** is working properly

### Loki Configuration
The Loki application needs updated credentials:
- Replace `your-grafana-loki-username` with actual username
- Replace `your-grafana-loki-api-key` with actual API key

### Sealed Secrets
The sealed secrets controller is kept in the `flux-system` namespace for compatibility with existing sealed secrets. This allows the existing encrypted secrets to continue working.

## FluxCD Migration Notes

### What was migrated:
1. **HelmReleases** → **ArgoCD Applications** with Helm sources
2. **HelmRepositories** → **ConfigMaps** with ArgoCD repository labels
3. **Plain manifests** → **Kustomization-based Applications**
4. **Flux notifications** → Will need to be configured in ArgoCD separately

### Key differences:
- ArgoCD uses `Applications` instead of `HelmReleases`
- Helm repositories are configured as ConfigMaps in the argocd namespace
- The "App of Apps" pattern replaces Flux's recursive kustomization
- ArgoCD has its own UI for monitoring and managing deployments

### Secrets handling:
- Sealed Secrets controller is kept for compatibility
- Existing sealed secrets should work without modification
- ArgoCD can also use its own secret management if needed

## Accessing Applications

After deployment, you can access:
- **ArgoCD UI**: http://argocd.local
- **Grafana** (if prometheus stack was enabled): http://grafana.local

## Troubleshooting

### Application sync issues:
```bash
# Check application status
kubectl get applications -n argocd

# Get detailed status
kubectl describe application <app-name> -n argocd

# Force sync an application
kubectl patch application <app-name> -n argocd --type merge -p='{"operation":{"sync":{"revision":"HEAD"}}}'
```

### Repository access issues:
```bash
# Check repository connections
kubectl get repositories -n argocd

# Update repository credentials if needed
kubectl edit secret <repo-secret> -n argocd
```

### Credential issues:
```bash
# Check if sealed secrets are working
kubectl get sealedsecrets -A

# Check if secrets are being created
kubectl get secrets -A | grep grafana
```

## Next Steps

1. **Deploy ArgoCD** using the steps above
2. **Monitor all applications** in ArgoCD UI
3. **Update credentials** for Grafana Cloud and Loki
4. **Configure ArgoCD notifications** (Slack, etc.)
5. **Set up ArgoCD RBAC** if needed
6. **Configure ArgoCD SSO** if desired
7. **Remove FluxCD components** once everything is working

## Cleanup Old FluxCD

Once ArgoCD is working properly, you can clean up the old FluxCD components:

```bash
# Use the cleanup script (interactive)
./argocd/cleanup-flux.sh

# Or manually remove FluxCD
kubectl delete namespace flux-system
```

## Backup

Your FluxCD configuration has been backed up to:
```
backup/flux-migration-YYYYMMDD/
```

You can restore from this backup if needed during the migration process.
