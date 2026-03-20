# k8s-azure-hardened

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AKS](https://img.shields.io/badge/AKS-1.29-0078D4?logo=microsoftazure)](https://learn.microsoft.com/en-us/azure/aks/)
[![Helm](https://img.shields.io/badge/Helm-3.14-0F1689?logo=helm)](https://helm.sh/)
[![CI](https://github.com/alilihic/k8s-azure-hardened/actions/workflows/aks-cicd.yml/badge.svg)](https://github.com/alilihic/k8s-azure-hardened/actions/workflows/aks-cicd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-hardened AKS cluster deployed via Terraform, with Calico network policies, Azure AD RBAC, ACR integration, and a production-grade Helm chart pattern. Designed for teams that need a secure, auditable Kubernetes environment on Azure from day one.

## Architecture

```
Azure Subscription
└── Resource Group: rg-k8s-<env>-weu
    ├── Virtual Network (10.10.0.0/16)
    │   ├── snet-aks-nodes   (10.10.1.0/24)  — kubelet, node agents
    │   ├── snet-aks-pods    (10.10.2.0/22)  — Azure CNI pod IPs
    │   └── snet-ingress     (10.10.6.0/24)  — internal load balancer
    ├── Azure Container Registry (Standard)
    │   └── Admin disabled — AKS uses AcrPull managed identity
    ├── AKS Cluster (1.29, zone-redundant)
    │   ├── System node pool  — tainted CriticalAddonsOnly, 3 zones
    │   ├── User node pool    — auto-scaling, 3 zones
    │   ├── Azure CNI networking + Calico network policies
    │   ├── Azure AD RBAC (local account disabled)
    │   ├── API server IP whitelisting
    │   ├── Container Insights → Log Analytics
    │   ├── Azure Policy add-on
    │   └── Automatic patch upgrade channel
    ├── Log Analytics Workspace
    │   └── AKS diagnostic logs: apiserver, audit, scheduler, guard
    └── Network Security Group (node subnet)
        └── Deny-all inbound default
```

## Security Hardening

| Control | Implementation |
|---------|---------------|
| No local admin account | `local_account_disabled = true` |
| Azure AD authentication | `azure_rbac_enabled = true` with AAD groups |
| API server restricted | `authorized_ip_ranges` whitelist |
| Network policy enforcement | Calico — default deny all, explicit allows |
| Non-root containers | `runAsNonRoot`, `runAsUser: 1000` in Helm chart |
| Read-only filesystem | `readOnlyRootFilesystem: true`, emptyDir for writes |
| Dropped capabilities | `capabilities.drop: [ALL]` |
| No privilege escalation | `allowPrivilegeEscalation: false` |
| Seccomp profile | `RuntimeDefault` |
| No ACR admin credentials | Kubelet managed identity with AcrPull role |
| Pod disruption budget | `minAvailable: 1` ensures availability during drain |
| Topology spread | Pods spread across nodes and availability zones |

## Prerequisites

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5.0 |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | latest |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | latest |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.14 |

## Quick Start

### 1. Clone and authenticate

```bash
git clone https://github.com/alilihic/k8s-azure-hardened.git
cd k8s-azure-hardened

az login
az account set --subscription "<subscription-id>"
```

### 2. Create an Azure AD group for cluster admins (optional but recommended)

```bash
az ad group create --display-name "k8s-admins" --mail-nickname "k8s-admins"
# Copy the object ID and set admin_group_object_id in terraform.tfvars
```

### 3. Deploy infrastructure

```bash
terraform init
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### 4. Bootstrap the cluster

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh \
  $(terraform output -raw resource_group_name) \
  $(terraform output -raw aks_cluster_name)
```

This installs `ingress-nginx`, `cert-manager`, applies RBAC manifests, and applies network policies.

### 5. Deploy the sample app

```bash
helm upgrade --install sample-app helm/charts/sample-app \
  --namespace production \
  --create-namespace \
  --set image.repository=$(terraform output -raw acr_login_server)/sample-app \
  --set image.tag=latest
```

## Network Policies

The `manifests/network-policies/` directory implements a zero-trust posture:

```
default-deny-all        → blocks all ingress + egress by default
allow-dns-egress        → UDP/TCP 53 (DNS must work)
allow-ingress-controller → ingress-nginx → app pods on :8080
allow-azure-egress      → HTTPS :443 to Azure APIs
allow-same-namespace    → intra-namespace pod communication
allow-monitoring-scrape → monitoring namespace → :9090/:8080
```

## RBAC Model

```
Azure AD Group: k8s-admins    → ClusterRoleBinding → cluster-admin
Azure AD Group: k8s-developers → RoleBinding (staging) → developer role
                               → RoleBinding (production) → readonly role
```

The `developer` role allows `pods/exec` and create/delete in staging — but only read in production.

## Helm Chart Features

The `helm/charts/sample-app` chart is a production template you can copy for real workloads:

- Rolling update strategy (`maxUnavailable: 0`)
- HPA on CPU + memory
- PodDisruptionBudget (`minAvailable: 1`)
- Topology spread across nodes and zones
- Per-pod NetworkPolicy (ingress from ingress-nginx only, egress DNS + HTTPS)
- Non-root, read-only filesystem, dropped capabilities
- Liveness and readiness probes
- `automountServiceAccountToken: false`

## CI/CD Pipeline

```
PR opened
  → lint (terraform fmt, validate, helm lint, kubeval)
  → plan (post as PR comment)

Merge to main
  → lint → plan → apply
  → kubectl apply rbac + network policies
  → helm upgrade --install (--atomic, --wait, 5m timeout)
```

## Repository Structure

```
k8s-azure-hardened/
├── main.tf                          # Root module
├── variables.tf / outputs.tf / locals.tf
├── terraform/
│   └── modules/
│       ├── aks/                     # AKS cluster + node pools + diagnostics
│       ├── acr/                     # Azure Container Registry
│       └── networking/              # VNet, subnets, NSG
├── helm/
│   └── charts/
│       └── sample-app/              # Production Helm chart template
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── deployment.yaml  # Security contexts, probes, topology spread
│               ├── service.yaml
│               ├── ingress.yaml
│               ├── hpa.yaml
│               ├── pdb-sa-netpol.yaml
│               └── _helpers.tpl
├── manifests/
│   ├── rbac/rbac.yaml               # Namespaces, ClusterRoles, RoleBindings
│   └── network-policies/            # Default deny + explicit allow rules
├── environments/
│   ├── dev/terraform.tfvars
│   └── prod/terraform.tfvars
├── scripts/
│   └── bootstrap.sh                 # Post-apply: ingress, cert-manager, manifests
└── .github/
    └── workflows/
        └── aks-cicd.yml             # Lint → Plan → Apply → Helm deploy
```

## Cost Estimate (West Europe, dev)

| Resource | SKU | Est. monthly |
|----------|-----|-------------|
| AKS system nodes (×2) | Standard_D2s_v3 | ~€140 |
| AKS user nodes (×2) | Standard_D4s_v3 | ~€280 |
| ACR | Standard | ~€18 |
| Log Analytics | PerGB2018 | ~€5 |
| Load Balancer | Standard | ~€18 |
| **Total** | | **~€461/month** |

> Tip: Scale node pools to 0 when not in use (`az aks nodepool scale --node-count 0`).

## License

MIT — see [LICENSE](LICENSE) for details.

---

*Part of my [Azure DevOps portfolio](https://github.com/alilihic). Also see:*
- *[azure-infra-baseline](https://github.com/alilihic/azure-infra-baseline) — Terraform Azure landing zone*
- *[azure-devops-ci-cd](https://github.com/alilihic/azure-devops-ci-cd) — GitHub Actions pipeline patterns*
