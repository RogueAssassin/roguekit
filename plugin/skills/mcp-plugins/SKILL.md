---
name: mcp-plugins
description: Use when choosing, adding, auditing or troubleshooting Claude Code MCP servers and plugins, especially to inspect, test or improve an existing UI or codebase (browser testing, live docs, performance). Invoke explicitly with /mcp-plugins when needed.
---
# MCP servers and plugins

## Principles
- Every MCP server and plugin adds tool/skill definitions to context. Add only what the task needs; check cost with `claude plugin details <name>` and `/context`; remove what is unused (`claude mcp remove <name>`).
- Third-party MCP servers run code with the user's permissions. Prefer official/first-party servers, pin versions where practical, review the source and requested access, and never put secrets in command lines or committed files. Add servers at user scope only when asked; project scope (`.mcp.json`) needs team agreement.
- Never add, enable or remove MCP servers/plugins silently or edit settings.json for them. Propose the exact `claude mcp add` / `claude plugin install` command and wait for approval.
- Prefer a simple CLI, built-in tool or targeted file read when it does the job cheaper than an MCP call.

## Choosing and vetting plugins
- Start from one recurring pain, not a category or a star count. Add at most 2-3 plugins for the user's lane (coding, research, token/memory pressure, design, writing); a long list is clutter and context cost.
- Before recommending an unfamiliar plugin, check: who publishes it and is the repo official/maintained; what it installs (hooks, MCP servers, npx/pip/bun packages, background services); what it can read or send (files, keys, network); what it stores and where; its license. Popularity is interest, not evidence of fit or safety.
- Treat blog and aggregator claims (e.g. "70x fewer tokens") as unverified. Measure on the user's own task with and without the plugin (`claude plugin details <name>`, `/context`) and keep it only if it earns its place.
- Plugins that observe every tool call (memory/capture hooks) can store secrets and source; check the exclusion mechanism and storage location first, and install only with the user's approval.
- Run `scripts/Install-RogueKit.ps1 -Action Audit` monthly to see always-on cost, then remove what is unused.

## Useful servers (opt-in; installer: -McpServers <name>)
- `context7`: current library/framework documentation. Use before changing code that depends on a library version, instead of guessing APIs.
- `playwright`: drive a real browser to reproduce UI bugs, check responsive layouts, accessibility snapshots and end-to-end flows against a running dev server (localhost only unless the user says otherwise).
- `chrome-devtools`: inspect live DOM/CSS, console, network and performance traces of a page being debugged.
- GitHub/Azure/database servers need credentials: set up by the user with least-privilege tokens, read-only first.

## Workflow for improving an existing UI or codebase
1. Read the project's instructions and run the app/tests as-is to get a baseline.
2. Use the narrowest tool: grep/targeted reads for code; Playwright or DevTools only to observe real rendered behaviour; context7 only for library questions.
3. Make small changes, re-verify in the browser or tests, and report what was and was not visually verified.

## Troubleshooting
- `claude mcp list` / `/mcp` shows connection state; on native Windows npx servers need `cmd /c npx ...`.
- `claude plugin list`, `claude plugin validate <path>`, then restart the session after changes.
- If the RogueKit token saver denies a call, follow its reason (ranged read, bounded command) rather than disabling it.
