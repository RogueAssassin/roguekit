# Azure checklist (load when designing or reviewing an Azure deployment)

## Identity and access
- Managed identities for workloads; no connection strings or keys in app settings when RBAC works.
- Least-privilege RBAC at the narrowest scope; Entra Conditional Access and MFA for humans; PIM for elevated roles.
- Secrets in Key Vault with RBAC, soft delete and purge protection.

## Networking
- Private endpoints for PaaS data services; public network access disabled where possible.
- NSGs default deny; hub-spoke or virtual WAN for larger estates; WAF in front of public web apps.

## Infrastructure as code
- Bicep or Terraform in source control; `what-if` / `plan` reviewed before apply; remote state with locking.
- Naming, tagging (owner, environment, cost-centre) and policy enforced via Azure Policy.
- Separate subscriptions or resource groups per environment; deployments through a pipeline using workload identity federation (no stored secrets).

## Reliability
- Pick availability zones or paired-region strategy deliberately; define RPO/RTO.
- Backups tested by restore; health probes; autoscale with sensible min/max.

## Monitoring
- Diagnostic settings to a Log Analytics workspace; Application Insights for apps; alerts with action groups.
- Defender for Cloud recommendations triaged.

## Cost
- Right-size SKUs; use reservations or savings plans for steady load; auto-shutdown for dev/test.
- Budgets and cost alerts per subscription; review orphaned disks, IPs and idle resources.
- Check current limits, prices and service retirements on Microsoft Learn rather than from memory.
