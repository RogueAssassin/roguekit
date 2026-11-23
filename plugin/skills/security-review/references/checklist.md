# Security review checklist (load when doing a full review)

## Input and output
- Every external input (HTTP, files, CLI args, env, queue messages) validated by type, length and allow-list.
- SQL/NoSQL/LDAP/OS-command built with parameters or argument arrays, never string concatenation.
- File paths normalised and confined to an allowed root (no `..`, no symlink escape).
- Output encoded for its context (HTML, attribute, JS, URL, shell, SQL).
- Deserialisation of untrusted data restricted to safe types; no `BinaryFormatter`, `pickle`, unsafe YAML load.
- Uploads: type, size and name checks; stored outside the web root; never executed.

## Authentication and sessions
- Passwords hashed with Argon2id/bcrypt/scrypt/PBKDF2; no custom crypto.
- Tokens expire, are revocable, and are not logged or put in URLs.
- Cookies: `Secure`, `HttpOnly`, `SameSite`; CSRF protection on state-changing requests.
- Rate limiting and lockout on login and reset flows.

## Authorisation
- Checked server-side on every request, per object (no IDOR), not just in the UI.
- Default deny; least privilege for service accounts and tokens.

## Secrets and configuration
- No secrets in source, logs, images, client bundles or error messages; scan history if one leaked and rotate it.
- Debug/diagnostic endpoints and verbose errors off in production.
- TLS everywhere; certificate validation never disabled; CORS not `*` with credentials.

## Dependencies and supply chain
- Versions pinned via lockfile; check known vulnerabilities (the `free-apis` skill: `lookup.ps1 -Kind Vulns`).
- CI actions pinned; no `curl | sh` in build steps; packages from expected registries.

## Logging and data
- Security events logged without sensitive values; log injection prevented.
- Personal data minimised, encrypted at rest where required, retention defined.

## Report format
For each finding: title, severity (realistic impact x exploitability), location (`file:line`), evidence, fix. Mark each as confirmed, likely, or hardening.
