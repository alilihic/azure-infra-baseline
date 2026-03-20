# azure-infra-baseline

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-AzureRM_3.90-0078D4?logo=microsoftazure)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![CI](https://github.com/alilihic/azure-infra-baseline/actions/workflows/terraform.yml/badge.svg)](https://github.com/alilihic/azure-infra-baseline/actions/workflows/terraform.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-ready Terraform baseline for Azure infrastructure. Provisions a secure, multi-environment Azure landing zone with networking, compute, identity, and secrets management — following Microsoft's Cloud Adoption Framework naming conventions and security best practices.

## Architecture

```
Azure Subscription
└── Resource Group: rg-<project>-<env>-<location>
    ├── Virtual Network (10.0.0.0/16)
    │   ├── AzureBastionSubnet  (10.0.0.0/27)
    │   ├── snet-workload       (10.0.1.0/24)
    │   └── snet-mgmt           (10.0.2.0/24)
    ├── Network Security Group (workload)
    │   ├── Deny all inbound (default)
    │   └── Allow VNet + LB probes
    ├── Azure Bastion (Basic SKU)
    │   └── Standard public IP (zone-redundant)
    ├── Key Vault
    │   ├── RBAC authorisation (not access policies)
    │   ├── Purge protection enabled
    │   └── Network ACL: Deny by default
    ├── Linux VM (Ubuntu 22.04 LTS)
    │   ├── SSH key auth only (no passwords)
    │   ├── System-assigned managed identity
    │   ├── Key Vault Secrets User RBAC role
    │   └── cloud-init: hardens SSH, installs Azure CLI + Terraform
    └── Network Watcher
```

## Features

- **Modular design** — networking, compute, security, and Key Vault are independent modules
- **Multi-environment** — separate `dev` and `prod` tfvars with different SKUs and address spaces
- **Security hardened** — NSG deny-all default, Bastion-only access, Key Vault network ACLs, purge protection
- **Managed identity** — VM authenticates to Key Vault without any stored credentials
- **CI/CD ready** — GitHub Actions workflow: validate → plan (with PR comments) → apply on merge
- **CAF naming** — all resources follow [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) conventions
- **cloud-init** — VM bootstraps with SSH hardening, UFW firewall, Azure CLI, and Terraform

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.5.0 | |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | latest | For local auth |
| An Azure subscription | — | Contributor + User Access Administrator role required |

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/alilihic/azure-infra-baseline.git
cd azure-infra-baseline
```

### 2. Authenticate to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 3. Generate an SSH key (if you don't have one)

```bash
ssh-keygen -t rsa -b 4096 -C "azure-infra-baseline"
cat ~/.ssh/id_rsa.pub  # Copy this value
```

### 4. Configure your environment

```bash
cp environments/dev/terraform.tfvars environments/dev/terraform.tfvars.local
# Edit the file and set your ssh_public_key
```

### 5. Deploy

```bash
terraform init
terraform plan -var-file="environments/dev/terraform.tfvars.local"
terraform apply -var-file="environments/dev/terraform.tfvars.local"
```

### 6. Connect to the VM via Bastion

```bash
# In the Azure Portal: VM → Connect → Bastion
# No public IP required on the VM
```

## Module Reference

### `modules/networking`

Provisions the Virtual Network, subnets (workload, AzureBastionSubnet, mgmt), and Network Watcher.

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `vnet_address_space` | `list(string)` | `["10.0.0.0/16"]` | VNet CIDR |
| `subnet_address_prefixes` | `object` | see variables.tf | Per-subnet CIDRs |

| Output | Description |
|--------|-------------|
| `vnet_id` | Resource ID of the VNet |
| `workload_subnet_id` | Resource ID of the workload subnet |
| `bastion_subnet_id` | Resource ID of AzureBastionSubnet |

### `modules/security`

Provisions the NSG (with deny-all default) and Azure Bastion host.

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `allowed_ssh_cidrs` | `list(string)` | `[]` | CIDRs for SSH NSG rule (dev only) |

| Output | Description |
|--------|-------------|
| `nsg_id` | Resource ID of the workload NSG |
| `bastion_hostname` | DNS name of the Bastion public IP |

### `modules/keyvault`

Provisions Key Vault with RBAC auth, network ACLs, and purge protection.

| Input | Type | Description |
|-------|------|-------------|
| `tenant_id` | `string` | Azure AD tenant ID |
| `admin_object_id` | `string` | Object ID granted Key Vault Administrator |
| `allowed_ip_rules` | `list(string)` | IPs allowed through network ACL |

| Output | Description |
|--------|-------------|
| `key_vault_id` | Resource ID of the Key Vault |
| `key_vault_uri` | Vault URI for SDK/CLI access |

### `modules/compute`

Provisions a Linux VM with managed identity, SSH-only auth, and cloud-init hardening.

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `vm_size` | `string` | `Standard_B2s` | Azure VM SKU |
| `admin_username` | `string` | `azureadmin` | Local admin username |
| `ssh_public_key` | `string` | — | SSH public key (sensitive) |

| Output | Description |
|--------|-------------|
| `vm_id` | Resource ID of the VM |
| `vm_private_ip` | Private IP address |
| `vm_identity_principal_id` | Managed identity principal ID |

## CI/CD

The GitHub Actions workflow runs on every PR and push to `main`:

```
PR opened  →  validate + fmt check  →  plan  →  post plan as PR comment
Merge to main  →  validate  →  plan  →  apply (auto-approve)
```

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Service principal app ID |
| `ARM_CLIENT_SECRET` | Service principal secret |
| `ARM_SUBSCRIPTION_ID` | Target subscription ID |
| `ARM_TENANT_ID` | Azure AD tenant ID |

### Create a service principal for CI

```bash
az ad sp create-for-rbac \
  --name "sp-terraform-baseline-ci" \
  --role "Contributor" \
  --scopes "/subscriptions/<subscription-id>"
```

> The service principal also needs **User Access Administrator** on the subscription to assign RBAC roles (Key Vault, VM managed identity).

## Security Considerations

- **No public IP on VM** — access is via Azure Bastion only
- **SSH password auth disabled** — key-based only, enforced in cloud-init
- **Key Vault network ACL** — default deny; add your IP or VNet service endpoint
- **Purge protection** — Key Vault cannot be permanently deleted for 90 days
- **RBAC over access policies** — granular, auditable, entra-native
- **Managed identity** — VM reads secrets without storing credentials anywhere
- **NSG deny-all** — inbound traffic blocked by default; only explicitly allowed traffic passes

## Cost Estimate (West Europe, dev environment)

| Resource | SKU | Est. monthly |
|----------|-----|-------------|
| Linux VM | Standard_B2s | ~€30 |
| Azure Bastion | Basic | ~€130 |
| Key Vault | Standard | ~€1 |
| Public IP | Standard | ~€3 |
| **Total** | | **~€164/month** |

> Tip: Deallocate the VM and Bastion when not in use to reduce dev costs significantly.

## Repository Structure

```
azure-infra-baseline/
├── main.tf                    # Root module — wires all modules together
├── variables.tf               # Root input variables
├── outputs.tf                 # Root outputs
├── locals.tf                  # Common tags and computed locals
├── .gitignore                 # Excludes state, secrets, .terraform/
├── .tflint.hcl                # Linting rules (azurerm ruleset)
├── .pre-commit-config.yaml    # Pre-commit: fmt, validate, docs, trivy scan
├── modules/
│   ├── networking/            # VNet, subnets, Network Watcher
│   ├── security/              # NSG, Azure Bastion
│   ├── keyvault/              # Key Vault with RBAC + network ACLs
│   └── compute/               # Linux VM with managed identity + cloud-init
├── environments/
│   ├── dev/terraform.tfvars   # Dev-specific values
│   └── prod/terraform.tfvars  # Prod-specific values (larger SKUs)
└── .github/
    └── workflows/
        └── terraform.yml      # Validate → Plan → Apply pipeline
```

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Run pre-commit checks: `pre-commit run --all-files`
4. Open a PR — the pipeline will post a Terraform plan automatically

## License

MIT — see [LICENSE](LICENSE) for details.

---

*Part of my [Azure DevOps portfolio](https://github.com/alilihic). Also see:*
- *[k8s-azure-hardened](https://github.com/alilihic/k8s-azure-hardened) — AKS + Helm + RBAC*
- *[azure-devops-ci-cd](https://github.com/alilihic/azure-devops-ci-cd) — GitHub Actions pipeline patterns*
