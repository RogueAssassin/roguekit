# Security

## Reporting a vulnerability
Please report security issues privately through GitHub's "Report a vulnerability" (Security tab) on this repository. Do not open a public issue. Include the file, what you observed, and how to reproduce it. We aim to acknowledge reports within 7 days.

## Scope and design
RogueKit is a Claude Code plugin made of Markdown skills, a PreToolUse hook and PowerShell helper scripts.

- It installs nothing, needs no administrator rights, creates no services, scheduled tasks or startup entries, and does not change execution policy.
- The hook (`plugin/hooks/token-guard.ps1`) is local only: no network, no files written, fails open.
- `lookup.ps1` sends only package names, versions and product names over HTTPS to public APIs.
- `ask-free.ps1` sends only text you pass it, to a provider you name, refuses text that looks like a secret, and stores keys only if you run `-Action SaveKey` (Windows DPAPI, current user).
- `ROGUEKIT_OFFLINE=1` disables all non-local network use.

See [docs/managed-devices.md](docs/managed-devices.md) for work or managed machines.

## Supported versions
Only the latest release receives fixes.
