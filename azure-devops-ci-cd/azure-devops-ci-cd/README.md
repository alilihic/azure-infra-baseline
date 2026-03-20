# azure-devops-ci-cd

[![CI](https://github.com/alilihic/azure-devops-ci-cd/actions/workflows/app-pipeline.yml/badge.svg)](https://github.com/alilihic/azure-devops-ci-cd/actions/workflows/app-pipeline.yml)
[![Security](https://github.com/alilihic/azure-devops-ci-cd/actions/workflows/security-scanning.yml/badge.svg)](https://github.com/alilihic/azure-devops-ci-cd/actions/workflows/security-scanning.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-grade GitHub Actions CI/CD pipeline library for Azure — featuring reusable workflows, security scanning, Terraform drift detection, and a multi-environment promotion model (dev → staging → prod with approval gates).

## Pipeline Architecture

```
PR opened
├── pr-validation.yml
│   ├── PR title (Conventional Commits)
│   ├── Terraform fmt + validate (changed .tf files only)
│   ├── Helm lint + template render (changed charts only)
│   └── Manifest validation (kubeconform)
└── security-scanning.yml
    ├── Gitleaks (secret detection)
    ├── Checkov (IaC: Terraform + K8s + Helm)
    ├── Trivy filesystem (dependency CVEs)
    └── tfsec (Terraform-specific security rules)

Push to main / tag v*.*.*
└── app-pipeline.yml
    ├── test          — lint, SAST, dependency audit, unit tests
    ├── build         → reusable-docker.yml
    │   ├── Multi-platform Docker build (Buildx)
    │   ├── OCI metadata labels + semantic tags
    │   ├── GitHub Actions cache (layer caching)
    │   └── Trivy image scan (CRITICAL+HIGH → fail)
    ├── deploy-dev    → reusable-helm-deploy.yml
    │   ├── helm diff (preview changes)
    │   ├── helm upgrade --install --atomic
    │   └── kubectl rollout status verify
    ├── smoke-test-dev
    ├── deploy-staging (on tag or manual)
    └── deploy-prod   (GitHub Environment approval gate)

Schedule: Mon–Fri 06:00 UTC
└── terraform-drift.yml
    ├── terraform plan -detailed-exitcode (all envs)
    ├── Drift → auto-creates GitHub Issue
    └── No drift → summary confirmation
```

## Workflows

### `reusable-terraform.yml` — Reusable Terraform workflow

Called by other workflows. Handles init, validate, fmt, plan, apply, destroy.

```yaml
jobs:
  deploy:
    uses: alilihic/azure-devops-ci-cd/.github/workflows/reusable-terraform.yml@main
    with:
      environment: dev
      action: apply
      var_file: environments/dev/terraform.tfvars
    secrets: inherit
```

### `reusable-docker.yml` — Reusable Docker build & push

Builds with Buildx, applies semantic tags, scans with Trivy, uploads SARIF to Security tab.

```yaml
jobs:
  build:
    uses: alilihic/azure-devops-ci-cd/.github/workflows/reusable-docker.yml@main
    with:
      image_name: my-app
      scan: true
      push: true
    secrets:
      ACR_LOGIN_SERVER: ${{ secrets.ACR_LOGIN_SERVER }}
      ACR_USERNAME:     ${{ secrets.ACR_USERNAME }}
      ACR_PASSWORD:     ${{ secrets.ACR_PASSWORD }}
```

### `reusable-helm-deploy.yml` — Reusable Helm deploy

Runs `helm diff` first, then `helm upgrade --install --atomic`, then verifies the rollout.

```yaml
jobs:
  deploy:
    uses: alilihic/azure-devops-ci-cd/.github/workflows/reusable-helm-deploy.yml@main
    with:
      environment:  prod
      release_name: my-app
      chart_path:   helm/charts/my-app
      namespace:    production
      image_tag:    sha-abc1234
    secrets: inherit
```

### `terraform-drift.yml` — Daily drift detection

Runs `terraform plan -detailed-exitcode` across all environments every weekday morning. Opens a GitHub Issue automatically if drift is detected — no silent infrastructure drift.

### `security-scanning.yml` — Security scanning suite

| Scanner | What it checks |
|---------|---------------|
| Gitleaks | Secrets and credentials in git history |
| Checkov | Terraform, Kubernetes, Helm misconfigurations |
| Trivy (fs) | CVEs in dependencies and packages |
| Trivy (image) | CVEs in built container images |
| tfsec | Terraform-specific security rules |

All results upload to GitHub Security tab as SARIF.

### `pr-validation.yml` — PR gate checks

- Enforces Conventional Commits in PR titles (`feat:`, `fix:`, `infra:`, `ci:`, etc.)
- Warns on large PRs (>500 lines changed)
- Only validates files that actually changed (no wasted runs)
- Validates Kubernetes manifests with `kubeconform` against K8s 1.29 schema

## Composite Actions

### `.github/actions/terraform-action`

Reusable composite action: sets up Terraform, exports Azure credentials, runs `terraform init`.

```yaml
- uses: ./.github/actions/terraform-action
  with:
    tf_version:          "1.7.0"
    arm_client_id:       ${{ secrets.ARM_CLIENT_ID }}
    arm_client_secret:   ${{ secrets.ARM_CLIENT_SECRET }}
    arm_subscription_id: ${{ secrets.ARM_SUBSCRIPTION_ID }}
    arm_tenant_id:       ${{ secrets.ARM_TENANT_ID }}
```

### `.github/actions/docker-action`

Builds a Docker image with short SHA tag using Buildx and GHA cache.

## Multi-environment Promotion Model

```
main branch  →  auto-deploy to dev
             →  smoke tests
tag v*.*.*   →  deploy to staging
             →  GitHub Environment approval (required reviewer)
             →  deploy to prod
```

GitHub Environments are used for the `prod` environment — configure **required reviewers** in `Settings → Environments → prod` to enforce manual approval before any production deploy.

## Required GitHub Secrets

| Secret | Description | Scope |
|--------|-------------|-------|
| `ARM_CLIENT_ID` | Service principal app ID | All |
| `ARM_CLIENT_SECRET` | Service principal secret | All |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID | All |
| `ARM_TENANT_ID` | Azure AD tenant ID | All |
| `ACR_LOGIN_SERVER` | ACR login server URL | Build |
| `ACR_USERNAME` | ACR username | Build |
| `ACR_PASSWORD` | ACR password | Build |
| `AKS_RESOURCE_GROUP_DEV` | Dev AKS resource group | Deploy |
| `AKS_CLUSTER_NAME_DEV` | Dev AKS cluster name | Deploy |
| `AKS_RESOURCE_GROUP_STAGING` | Staging AKS resource group | Deploy |
| `AKS_CLUSTER_NAME_STAGING` | Staging AKS cluster name | Deploy |
| `AKS_RESOURCE_GROUP_PROD` | Prod AKS resource group | Deploy |
| `AKS_CLUSTER_NAME_PROD` | Prod AKS cluster name | Deploy |

## Scripts

### `scripts/smoke-test.sh`

HTTP smoke tests against a deployed endpoint. Retries with backoff.

```bash
./scripts/smoke-test.sh https://my-app.example.com
```

Checks: `/healthz`, `/ready`, `/`, `/metrics`, and a 404 negative test.

### `scripts/rollback.sh`

Rolls back a Helm release to the previous (or specified) revision.

```bash
# Roll back to previous revision
./scripts/rollback.sh my-app production

# Roll back to specific revision
./scripts/rollback.sh my-app production 3
```

## Dockerfile

The included `Dockerfile` demonstrates production best practices:

- Multi-stage build (builder + runtime) — keeps final image lean
- Non-root user (`appuser:1000`)
- OCI labels for traceability (`BUILD_DATE`, `VCS_REF`)
- `HEALTHCHECK` instruction
- `PYTHONDONTWRITEBYTECODE` + `PYTHONUNBUFFERED`

## Repository Structure

```
azure-devops-ci-cd/
├── .github/
│   ├── workflows/
│   │   ├── app-pipeline.yml          # Main orchestrator: test → build → deploy
│   │   ├── reusable-terraform.yml    # Reusable: tf init/plan/apply/destroy
│   │   ├── reusable-docker.yml       # Reusable: build, tag, scan, push
│   │   ├── reusable-helm-deploy.yml  # Reusable: diff, upgrade, verify
│   │   ├── terraform-drift.yml       # Scheduled drift detection
│   │   ├── security-scanning.yml     # Gitleaks, Checkov, Trivy, tfsec
│   │   └── pr-validation.yml         # PR title, fmt, lint, manifest validation
│   └── actions/
│       ├── terraform-action/         # Composite: setup TF + Azure auth
│       └── docker-action/            # Composite: build + tag with short SHA
├── scripts/
│   ├── smoke-test.sh                 # HTTP smoke tests with retry
│   └── rollback.sh                   # Helm rollback helper
├── Dockerfile                        # Multi-stage, non-root, OCI labels
└── docs/
    └── pipeline-decisions.md         # ADRs for pipeline design choices
```

## License

MIT — see [LICENSE](LICENSE) for details.

---

*Part of my [Azure DevOps portfolio](https://github.com/alilihic). Also see:*
- *[azure-infra-baseline](https://github.com/alilihic/azure-infra-baseline) — Terraform Azure landing zone*
- *[k8s-azure-hardened](https://github.com/alilihic/k8s-azure-hardened) — AKS + Helm + RBAC*
