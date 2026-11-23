# Changelog

## 1.5.0

- New skill `free-model-assist` with `ask-free.ps1`: hand small side tasks to free or local OpenAI-compatible APIs (Groq, OpenRouter, Gemini, NVIDIA, Mistral, GitHub Models, Cerebras, Ollama, LM Studio, custom). PowerShell only, nothing to install; optional DPAPI-encrypted key storage; HTTPS enforced; secret-looking prompts refused; ordered fallback and retry.
- New skill `free-apis` with `lookup.ps1`: current package versions (npm, PyPI, NuGet, Maven, crates.io), vulnerabilities (OSV), end-of-life dates (endoflife.date) and GitHub releases. No keys, nothing written to disk.
- New documentation set in `docs/`: skills, agents, hook and rules, installer, free model assist, free APIs, managed devices.
- Managed-device hardening: the hook and helper scripts no longer need `-ExecutionPolicy Bypass`, work in PowerShell Constrained Language Mode, and avoid patterns endpoint-protection tools commonly flag. New `ROGUEKIT_OFFLINE=1` switch disables all remote lookups and remote models. `docs/managed-devices.md` documents files, network endpoints and what IT should review; compatibility with any specific security product cannot be guaranteed.
- Removed `-WithGraphify`, uv and Python management from the installer; RogueKit no longer installs anything beyond the plugin. `graphify-guide` is now guidance only.
- Installer: Audit regex fixed and now reports the token cost of plugin descriptions; Doctor checks the helper scripts and no longer bypasses execution policy.
- New `scripts/Test-RogueKit.ps1` (structure, managed-device hygiene, secret and attribution scan, hook scenarios in both language modes, `ask-free.ps1` against a local fake provider; `-Action Manifest` prints SHA-256 hashes) and a GitHub Actions workflow that runs it. Added `SECURITY.md` and `CONTRIBUTING.md`.
- New on-demand references for `security-review`, `api-automation` and `azure-cloud`.
- `ask-free.ps1` honours `ROGUEKIT_HOME` (state folder override, used by tests).
- `commsatlas` moved out of the shipped plugin into the CommsAtlas repository as a project skill. Copyright holder is now "RogueKit Developers".

## 1.4.0

- New skills derived from the maintainer's repositories and sessions: `selfhosted-containers`, `linux-server-admin` (lockout-safe SSH port changes), `php-wordpress`, `flutter-dart`, `android-root-modules`.
- `rust-oxide-carbon`: Oxide extension (DLL) guidance and use of the Rust reference data for verification. `git-github-ci`: release hygiene (version, changelog, checksums, upload lists).

## 1.3.0

- New `commsatlas` skill: architecture, build/test/release workflow (`--selftest`, `build.ps1 -Test`, `.run` installer, `BUILD-LOG.md`), and project rules (no live deploys without approval, read-only UniFi connector, tenant and auth safety, no real customer data) for coding and updating CommsAtlas.

## 1.2.1

- Installer: `Doctor` and `Status` no longer report the plugin as missing on Claude Code 2.1.3xx, where `claude plugin list` uses a different pointer glyph that Windows PowerShell 5.1 garbles. The plugin entry is now matched by its `name@marketplace` line.

## 1.2.0

- New on-demand `references/quality-and-performance.md` for `dotnet-csharp`, `java-development`, `python-development`, `powershell-windows`, `frontend-ui-ux` and `sql-database`: cheapest verification commands, common error classes, how to measure, and a table of performance alternatives to try.
- `performance-review` now points to those references. No new always-on cost beyond one added line per skill body.

## 1.1.0

- `rust-oxide-carbon` skill rewritten for the real stack: Facepunch Rust on Unity, C# only (legacy Oxide Lua/JS/Python noted as unmaintained), Oxide vs Carbon (modern C# and Harmony) targeting, main-thread and lifecycle rules, hook return semantics and hot-path performance.
- IDE support: reference-only `.csproj`, `.editorconfig`, VS Code task, Visual Studio/Rider/VS Code notes, how to use Claude Code IDE selection and diagnostics, and a diagnostics table.
- New on-demand references: `ide-setup.md`, `plugin-templates.md` (Oxide, Carbon, Harmony, dual-framework) and `review-checklist.md`.

## 1.0.0

First release under the RogueKit name (continues the earlier "ClaudePack" 2.x line).

- Distributed as a native Claude Code plugin marketplace (`roguekit`) instead of copying files into `~/.claude`.
- 20 skills, 5 agents (Sonnet by default; Opus for `architect` and `deep-debugger`), local token-saver hook.
- New skills: `plan-and-verify`, `session-handoff`, `context-budget`.
- Global rules ship as one marked block in `CLAUDE.md` with backup, idempotent updates and clean removal.
- New installer `scripts/Install-RogueKit.ps1`: `Install`, `Status`, `Doctor`, `Audit`, `Uninstall`; everything supports `-WhatIf`.
- Automatic, hash-checked migration from ClaudePack (modified files are kept).
- Opt-in extras: `-McpServers` (context7, playwright, chrome-devtools) and `-WithGraphify` (uv + Python + Graphify under `-UvDir`, SHA-256 verified).
- Environment variables renamed to `ROGUEKIT_TOKEN_SAVER` and `ROGUEKIT_READ_MAX_KB`; the old `CLAUDEPACK_*` names still work.
- Removed the Dahl Inference skill.
