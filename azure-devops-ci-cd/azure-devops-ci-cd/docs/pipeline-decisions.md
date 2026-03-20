# Pipeline Design Decisions

Architecture Decision Records (ADRs) for the CI/CD pipeline design in this repo.

---

## ADR-001: Reusable workflows over copy-paste

**Decision:** All shared pipeline logic lives in `reusable-*.yml` files called via `workflow_call`.

**Rationale:** Duplicating pipeline steps across repos leads to drift — a security fix in one pipeline doesn't propagate to others. Reusable workflows enforce a single source of truth. Consumers pin to `@main` or a specific tag.

**Trade-off:** Reusable workflows have stricter secret passing rules (`secrets: inherit` or explicit forwarding). Slightly more upfront complexity.

---

## ADR-002: Terraform drift detection via scheduled plan

**Decision:** Run `terraform plan -detailed-exitcode` on a schedule (Mon–Fri 06:00 UTC) and open a GitHub Issue on drift.

**Rationale:** Infrastructure managed by Terraform can drift due to manual changes in the Azure Portal, Azure Policy remediations, or resource auto-updates. Silent drift causes incidents. A daily check surfaces problems before they cause outages.

**Trade-off:** Requires backend state configured. False positives possible on resources with auto-rotating properties (e.g. expiring SAS tokens). These should use `lifecycle { ignore_changes }`.

---

## ADR-003: Trivy image scan blocks the pipeline on CRITICAL/HIGH

**Decision:** `exit-code: "1"` on CRITICAL and HIGH CVEs in `reusable-docker.yml`.

**Rationale:** Pushing vulnerable images to production is a worse outcome than a failed build. Developers must acknowledge CVEs explicitly (by updating base images or adding suppressions) rather than having them silently ship.

**Trade-off:** Can create friction when upstream base images have unpatched CVEs. Mitigation: use `trivyignore` files for accepted false positives, and update base images on a regular cadence.

---

## ADR-004: GitHub Environments for prod approval gate

**Decision:** The `prod` environment in `app-pipeline.yml` uses a GitHub Environment with required reviewers.

**Rationale:** Human approval before production deployments is a standard control in regulated and high-availability environments. GitHub Environments provide this natively without external tooling.

**Trade-off:** Requires GitHub Team or Enterprise for private repos. Free public repos support it natively.

---

## ADR-005: `helm upgrade --atomic` for zero-failed-deploy guarantee

**Decision:** All Helm deploys use `--atomic` flag.

**Rationale:** `--atomic` automatically rolls back to the previous release if the deploy fails (pods crash, readiness probe fails, etc.). Without it, a failed deploy leaves the cluster in a broken intermediate state that requires manual intervention.

**Trade-off:** Increases deploy time — Helm waits for the full `--timeout` before rolling back a bad deploy. Set timeout appropriately per environment (shorter for dev, longer for prod).

---

## ADR-006: Only validate changed files in PR checks

**Decision:** `pr-validation.yml` uses `tj-actions/changed-files` to only lint/validate files that changed in the PR.

**Rationale:** Running `terraform validate` on the entire repo for a docs change wastes 2-3 minutes per PR. Scoped validation makes PR feedback faster and reduces GitHub Actions minutes consumption.

**Trade-off:** A change to a shared module might not trigger validation of dependent configurations. Mitigated by full validation on merge to main.
