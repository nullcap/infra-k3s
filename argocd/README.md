# ArgoCD Migration with Sealed Secrets

This directory contains the ArgoCD configuration for migrating from FluxCD to ArgoCD with Sealed Secrets for secret management.

## Directory Structure

```
argocd/
├── install/
│   ├── argocd-namespace.yaml    # ArgoCD namespace
│   └── argocd-install.yaml      # ArgoCD installation Application
├── helm-repositories/
│   └── grafana.yaml             # Grafana Helm repository
├── applications/
│   ├── infrastructure.yaml     # Infrastructure components
│   ├── sealed-secrets.yaml     # Sealed Secrets Controller
│   ├── grafana-k8s-monitoring.yaml  # Grafana Cloud monitoring
│   ├── kube-prometheus-stack.yaml  # Local monitoring stack
│   ├── loki-grafanacloud.yaml  # Loki/Promtail for Grafana Cloud
│   ├── archivetw.yaml          # Archive Team Warrior
│   └── monitoring-secrets.yaml # Monitoring secrets (now empty)
├── manifests/
│   ├── infrastructure/         # Infrastructure manifests
│   ├── archivetw/             # Archive Team Warrior manifests
│   └── monitoring-secrets/    # Empty (migrated to Sealed Secrets)
├── root-app.yaml              # Root Application of Applications
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
- **Sealed Secrets integration**
- **Pure GitOps approach with no shell scripts**

⚠️ **Needs Attention:**
- Sealed Secrets controller needs to be deployed
- Secrets need to be migrated to Sealed Secrets format
- Grafana Cloud credentials need to be stored as Sealed Secrets

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

### Secret Management
- **Sealed Secrets**: Manages secrets in sealed secret format
- **Grafana Cloud**: Grafana Cloud monitoring stack (uses Sealed Secrets)
- **kube-prometheus-stack**: Local monitoring stack with Prometheus and Grafana (uses NFS storage)
- **loki-grafanacloud**: Loki stack with Promtail for log shipping to Grafana Cloud

### Applications
- **archivetw**: Archive Team Warrior deployment

## Sealed Secrets Setup

### Sealed Secrets Controller
- **Deployment**: Deployed via Helm chart or manifest
- **UI Access**: Available at http://sealed-secrets.local

### Sealed Secrets Configuration
- **SecretStore**: Configured to connect to Sealed Secrets
- **Service Accounts**: Created for authentication
- **Sealed Secrets**: Configured for all monitoring secrets

### Secret Migration
The following secrets have been migrated from sealed secrets to Sealed Secrets:
- Grafana Cloud credentials
- Monitoring stack credentials
- Application-specific secrets

### Grafana Cloud Configuration
The Grafana Cloud monitoring application now uses Sealed Secrets:
- All passwords are retrieved from Sealed Secrets
- No manual credential updates needed
- Automatic secret rotation support

### Sealed Secrets
1. **Automatic Sync**: Sealed Secrets automatically syncs secrets
2. **Service Accounts**: Proper RBAC configured for secret access
3. **Refresh Interval**: Secrets are refreshed automatically

### Grafana Cloud Configuration
The Grafana Cloud monitoring application now uses Sealed Secrets:
- All passwords are retrieved from Sealed Secrets
- No manual credential updates needed
- Automatic secret rotation support

### Additional Considerations
- Consider storing these in Sealed Secrets as well

## Important Notes

### Sealed Secrets
1. **Automatic Sync**: Sealed Secrets automatically syncs secrets
2. **Service Accounts**: Proper RBAC configured for secret access
3. **Refresh Interval**: Secrets are refreshed every hour

### Grafana Cloud Configuration
The Grafana Cloud monitoring application now uses Sealed Secrets:
- All passwords are retrieved from Sealed Secrets
- No manual credential updates needed
- Automatic secret rotation support

### Loki Configuration
The Loki application needs updated credentials:
- Replace `your-grafana-loki-username` with actual username
- Replace `your-grafana-loki-api-key` with actual API key
- Consider storing these in Sealed Secrets as well

## FluxCD Migration Notes

### What was migrated:
1. **HelmReleases** → **ArgoCD Applications** with Helm sources
2. **HelmRepositories** → **ConfigMaps** with ArgoCD repository labels
3. **Plain manifests** → **Kustomization-based Applications**
4. **Sealed Secrets** → **Sealed Secrets (simplified)**
5. **Flux notifications** → Will need to be configured in ArgoCD separately

### Key differences:
- ArgoCD uses `Applications` instead of `HelmReleases`
- Helm repositories are configured as ConfigMaps in the argocd namespace
- The "App of Apps" pattern replaces Flux's recursive kustomization
- Sealed Secrets for simple and reliable secret management
- ArgoCD has its own UI for monitoring and managing deployments
- **Pure GitOps approach with no manual scripts**

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

### Sealed Secrets issues:
```bash
# Check Sealed Secrets status
kubectl get sealedsecrets -A

# Check Sealed Secrets Controller logs
kubectl logs -n kube-system deployment/sealed-secrets-controller

# Check if secrets are being created
kubectl get secrets -A | grep sealed
```

## Next Steps

1. **Deploy ArgoCD** using the steps above
2. **Deploy Sealed Secrets Controller** via ArgoCD
3. **Create sealed secrets** for your applications
4. **Monitor all applications** in ArgoCD UI
5. **Configure ArgoCD notifications** (Slack, etc.)
6. **Set up ArgoCD RBAC** if needed
7. **Configure ArgoCD SSO** if desired
8. **Remove FluxCD components** once everything is working

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
