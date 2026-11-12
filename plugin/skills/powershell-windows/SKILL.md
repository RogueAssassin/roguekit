---
name: powershell-windows
description: Use for PowerShell scripts, Windows automation, installers, packaging, registry/service/process management and deployment tooling.
---
# PowerShell and Windows automation
- Identify the supported PowerShell edition/version and Windows environment; preserve Windows PowerShell 5.1 compatibility when required.
- Use approved verbs, parameter validation, comment-based help where useful, and predictable exit codes.
- Prefer `-LiteralPath`, explicit encoding, `try/catch/finally`, and deliberate `$ErrorActionPreference` handling.
- Make scripts idempotent where practical. Support `-WhatIf`/`ShouldProcess` for destructive or system-changing operations.
- Back up files before replacement; verify hashes before rollback or deletion so later user edits are not lost.
- Quote paths safely, handle spaces and non-ASCII paths, and avoid assuming the current working directory.
- Do not weaken execution policy persistently. If a process-scoped bypass is needed, explain it and keep its scope limited to that PowerShell process.
- Never embed credentials. Avoid logging secrets and validate downloaded artifacts before execution.
- Test syntax and behaviour on the declared PowerShell versions; do not claim execution testing if only static inspection was performed.
