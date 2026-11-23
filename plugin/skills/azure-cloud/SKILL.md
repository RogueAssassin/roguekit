---
name: azure-cloud
description: Use for Azure architecture, identity, networking, infrastructure as code, deployment, monitoring and cost-aware cloud operations.
---
# Azure and cloud
- Identify subscription, environment, resource group and deployment architecture before proposing changes.
- Prefer managed identities, least-privilege RBAC, Key Vault and private networking where appropriate.
- Follow existing Bicep, Terraform, ARM or pipeline conventions.
- Review cost, security, availability, observability and rollback implications before provisioning.
- Distinguish development, test and production. Never deploy, delete or modify production resources without explicit approval.
- Validate plans and deployment diffs before execution; prefer official vendor documentation.
- For design or review, read `references/azure-checklist.md` in this skill folder.
