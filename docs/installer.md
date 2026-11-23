# Installer reference (`scripts/Install-RogueKit.ps1`)

Windows PowerShell 5.1 or PowerShell 7. Every change supports `-WhatIf` (preview, changes nothing). Run it from the repository folder with `powershell -File scripts/Install-RogueKit.ps1` under your existing execution policy; RogueKit never asks you to bypass it. On managed or work devices read [managed-devices.md](managed-devices.md) first.

## Actions

| Command | What it does |
|---|---|
| `.\scripts\Install-RogueKit.ps1` | **Install** (default): adds the managed rules block to `~/.claude/CLAUDE.md` (with backup), registers the `roguekit` marketplace, installs the plugin, migrates a ClaudePack install if found. |
| `-Action Status` | Shows repo, config dir, CLI path, plugin state, rules block, old-pack detection. |
| `-Action Doctor` | PASS/WARN/FAIL checks: PowerShell, Claude CLI, plugin installed and enabled, token-saver hook behaves, exactly one rules block, no duplicate user-level skills. Exit code reflects failures. |
| `-Action Audit` | Estimates always-on token cost of rules, skills, plugins, MCP servers. Run monthly. |
| `-Action Uninstall` | Removes the plugin, marketplace entry and rules block (with backup). Does not remove MCP servers or `~/.roguekit`. |

## Options

| Option | Meaning |
|---|---|
| `-Source <path-or-owner/repo>` | Marketplace source. Default: this folder. Use `RogueAssassin/roguekit` to install from GitHub so the clone can be deleted. |
| `-SkipPlugin` / `-SkipRules` | Install only the rules, or only the plugin. |
| `-KeepOldPack` | Do not migrate/remove an old ClaudePack install. |
| `-McpServers context7,playwright,chrome-devtools` | Opt-in MCP servers (need Node.js 18+; each adds tool definitions to every session). |

## What it writes

- `~/.claude/CLAUDE.md` (marked block only), backups in `~/.roguekit/backups/`.
- `~/.roguekit/state.json`.
- The plugin through the `claude plugin` CLI (not by editing `settings.json`).

It never edits credentials, `settings.json`, MCP files or project files.

## Updating

```powershell
git pull
claude plugin marketplace update roguekit
claude plugin update roguekit@roguekit
```

Then restart Claude Code. If you move the repository folder, re-add the marketplace: `claude plugin marketplace remove roguekit`, then `claude plugin marketplace add <new path>`, then `claude plugin install roguekit@roguekit`.

## Nothing else to install

The free model and free API helpers are plain PowerShell scripts inside the plugin (`free-model-assist`, `free-apis`). They are not installed by this script, need nothing beyond Windows PowerShell, and change nothing until you run them. See [free-model-assist.md](free-model-assist.md) and [free-apis.md](free-apis.md).
