---
name: api-automation
description: Use for REST APIs, OpenAPI, integrations, automation, webhooks, CI/CD and reliable service-to-service workflows.
---
# APIs and automation
- Inspect API contracts, authentication, rate limits and existing integration patterns.
- Prefer documented APIs and supported SDKs; validate request/response schemas.
- Handle pagination, timeouts, retries, backoff and rate limits. Make retries idempotent where possible.
- Keep credentials in approved secret stores or environment configuration; never hardcode tokens.
- Log useful diagnostic metadata without exposing credentials or sensitive payloads.
- Test with safe representative data and avoid destructive automation without approval.
- For design or review, read `references/api-checklist.md` in this skill folder.
