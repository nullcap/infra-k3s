# ArgoCD Migration with External Secrets + Vault

This directory contains the ArgoCD configuration for migrating from FluxCD to ArgoCD with External Secrets Operator (ESO) and HashiCorp Vault for secret management.

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
│   ├── external-secrets-operator.yaml  # External Secrets Operator
│   ├── vault.yaml              # HashiCorp Vault
│   ├── vault-init.yaml         # Vault initialization
│   ├── external-secrets.yaml   # External Secrets configuration
│   ├── grafana-k8s-monitoring.yaml  # Grafana Cloud monitoring
│   ├── kube-prometheus-stack.yaml  # Local monitoring stack
│   ├── loki-grafanacloud.yaml  # Loki/Promtail for Grafana Cloud
│   ├── archivetw.yaml          # Archive Team Warrior
│   └── monitoring-secrets.yaml # Monitoring secrets (now empty)
├── manifests/
│   ├── infrastructure/         # Infrastructure manifests
│   ├── archivetw/             # Archive Team Warrior manifests
│   ├── monitoring-secrets/    # Empty (migrated to External Secrets)
│   ├── external-secrets/      # External Secrets configuration
│   └── vault-init/            # Vault initialization jobs
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
- **External Secrets Operator + Vault integration**
- **Sealed secrets removed and replaced with External Secrets**
- **Pure GitOps approach with no shell scripts**

⚠️ **Needs Attention:**
- Vault needs to be initialized and configured (handled via GitOps)
- Secrets need to be migrated from sealed secrets to Vault
- Grafana Cloud credentials need to be stored in Vault
- Loki Grafana Cloud credentials need to be updated

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
- **External Secrets Operator**: Manages secrets from external sources
- **Vault**: HashiCorp Vault for secret storage
- **Vault Init**: Automated Vault initialization and configuration
- **External Secrets Config**: Configuration for secret retrieval

### Monitoring
- **grafana-k8s-monitoring**: Grafana Cloud monitoring stack (uses External Secrets)
- **kube-prometheus-stack**: Local monitoring stack with Prometheus and Grafana (uses NFS storage)
- **loki-grafanacloud**: Loki stack with Promtail for log shipping to Grafana Cloud

### Applications
- **archivetw**: Archive Team Warrior deployment

## External Secrets + Vault Setup

### Vault Configuration
- **Automated Initialization**: Vault is automatically initialized via Kubernetes jobs
- **KV Secrets Engine**: Enabled at `/secret` path
- **Kubernetes Auth**: Configured for service account authentication
- **UI Access**: Available at http://vault.local

### External Secrets Configuration
- **SecretStore**: Configured to connect to Vault
- **Service Accounts**: Created for authentication
- **External Secrets**: Configured for all monitoring secrets

### Secret Migration
The following secrets have been migrated from sealed secrets to Vault:
- **Grafana Cloud**: metrics-password, logs-password, otlp-password, profiles-password, fm-password
- **Grafana Admin**: admin-user, admin-password
- **Slack**: api-url

## Important Notes

### Vault Setup (GitOps)
1. **Automatic Initialization**: Vault is initialized automatically via Kubernetes jobs
2. **Configuration**: Vault is configured automatically with secrets engine and auth
3. **Placeholder Secrets**: Initial placeholder secrets are created automatically
4. **Manual Secret Updates**: You'll need to update the placeholder secrets with real values

### External Secrets
1. **Automatic Sync**: External Secrets Operator automatically syncs secrets from Vault
2. **Service Accounts**: Proper RBAC configured for secret access
3. **Refresh Interval**: Secrets are refreshed every hour

### Grafana Cloud Configuration
The Grafana Cloud monitoring application now uses External Secrets:
- All passwords are retrieved from Vault via External Secrets
- No manual credential updates needed
- Automatic secret rotation support

### Loki Configuration
The Loki application needs updated credentials:
- Replace `your-grafana-loki-username` with actual username
- Replace `your-grafana-loki-api-key` with actual API key
- Consider storing these in Vault as well

## FluxCD Migration Notes

### What was migrated:
1. **HelmReleases** → **ArgoCD Applications** with Helm sources
2. **HelmRepositories** → **ConfigMaps** with ArgoCD repository labels
3. **Plain manifests** → **Kustomization-based Applications**
4. **Sealed Secrets** → **External Secrets + Vault**
5. **Flux notifications** → Will need to be configured in ArgoCD separately

### Key differences:
- ArgoCD uses `Applications` instead of `HelmReleases`
- Helm repositories are configured as ConfigMaps in the argocd namespace
- The "App of Apps" pattern replaces Flux's recursive kustomization
- External Secrets + Vault replaces sealed secrets for better secret management
- ArgoCD has its own UI for monitoring and managing deployments
- **Pure GitOps approach with no manual scripts**

## Accessing Applications

After deployment, you can access:
- **ArgoCD UI**: http://argocd.local
- **Vault UI**: http://vault.local
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

### External Secrets issues:
```bash
# Check External Secrets status
kubectl get externalsecrets -A

# Check External Secrets Operator logs
kubectl logs -n external-secrets-system deployment/external-secrets

# Check Vault connection
kubectl get secretstore -A
```

### Vault issues:
```bash
# Check Vault status
kubectl get pods -n vault

# Check Vault logs
kubectl logs -n vault vault-0

# Check Vault initialization jobs
kubectl get jobs -n vault

# Access Vault CLI
kubectl exec -it -n vault vault-0 -- vault status
```

## Next Steps

1. **Deploy ArgoCD** using the steps above
2. **Monitor Vault initialization** in ArgoCD UI
3. **Update placeholder secrets** in Vault with real values
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
