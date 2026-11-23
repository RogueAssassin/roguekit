# API and integration checklist (load when designing or reviewing an API or automation)

## Contract
- OpenAPI spec is the source of truth; validate requests and responses against it in tests.
- Consistent resource naming, status codes, error body (`code`, `message`, `details`, correlation id).
- Version explicitly (path or header); additive changes only within a version; document deprecations.
- Pagination (cursor preferred), filtering and sorting defined up front; cap page size.

## Reliability
- Timeouts on every outbound call; retry only idempotent calls, with exponential backoff and jitter; honour `Retry-After`.
- Idempotency keys for POSTs that create or charge.
- Circuit breaker or bulkhead for flaky dependencies; fail fast instead of queueing forever.
- Webhooks: verify signature and timestamp, respond fast (2xx), process asynchronously, dedupe by event id, tolerate replays and out-of-order delivery.

## Security
- Auth on every endpoint (OAuth2/OIDC or scoped keys); least-privilege scopes; keys in a secret store.
- Validate input, limit body size, rate limit per client, avoid mass assignment.
- No secrets or personal data in URLs or logs.

## CI/CD and automation
- Pipelines are idempotent and re-runnable; pin tool and action versions.
- Secrets via the CI secret store; least-privilege tokens; no secrets in logs.
- Contract tests plus a smoke test after deploy; rollback path documented.

## Observability
- Structured logs with correlation ids, latency and error-rate metrics, alerts on SLO breach.
