# RogueKit

A lean, token-conscious toolkit for [Claude Code](https://claude.com/claude-code) on Windows: engineering skills, review/debug/architecture agents, a local token-saver hook, and a small set of global rules. **Sonnet by default, Opus only when the job needs it.**

RogueKit is an independent community project. It is not affiliated with or endorsed by Anthropic.

## What you get

| Part | What it is | Context cost |
|---|---|---|
| **Plugin `roguekit`** | 20 skills, 5 agents, 1 hook, installed through Claude Code's native plugin system | Skill/agent *descriptions* only; skill bodies load when used |
| **Global rules** | One marked block appended to your `~/.claude/CLAUDE.md` (the one thing a plugin cannot ship) | About 1.3k tokens every session |
| **Installer** | `scripts/Install-RogueKit.ps1`: install, doctor, audit, uninstall, optional extras | None |

Run `.\scripts\Install-RogueKit.ps1 -Action Audit` any time to see the real numbers on your machine.

### Skills

Skills load on demand. Claude picks them when the task matches their description, or you can invoke one by name (plugin skills show up as `roguekit:<name>` when you type `/`).

| Skill | Use it for |
|---|---|
| `plan-and-verify` | Plan, test first, implement, fresh-context review, verify, for non-trivial changes |
| `session-handoff` | Save or resume a compact handoff note before `/clear` or when pausing |
| `context-budget` | Diagnose what is eating your context and pick the smallest fix |
| `model-routing` | When to stay on Sonnet and when to escalate to Opus |
| `token-efficiency` | Token-aware workflow for long or heavy sessions |
| `mcp-plugins` | Choosing, vetting, auditing MCP servers and plugins |
| `graphify-guide` | When and how to use Graphify on large codebases |
| `dotnet-csharp`, `java-development`, `python-development`, `rust-oxide-carbon`, `powershell-windows` | Language and platform guidance |
| `frontend-ui-ux`, `sql-database`, `azure-cloud`, `api-automation`, `git-github-ci` | Frontend, data, cloud, APIs, Git/CI |
| `game-server-tooling` | Dedicated game server managers, SteamCMD, RCON |
| `security-review`, `performance-review` | Security audits and profiling-led optimisation |

### Agents

| Agent | Model | Use it for |
|---|---|---|
| `code-reviewer` | Sonnet | Review a diff from a fresh context |
| `debugger` | Sonnet | Reproduce and root-cause bugs |
| `architect` | **Opus** | Architecture and migration design |
| `deep-debugger` | **Opus** | Escalation for bugs that survived two fix attempts |
| `context-auditor` | Haiku | Read-only audit of context and token waste |

### Token-saver hook

A local `PreToolUse` hook denies, with a reason Claude can act on:

- `Read` of files over 150 KB with no `limit`, lockfiles, minified bundles, source maps, and anything inside `node_modules` or `.git/objects`.
- `git log` with no count or date bound.

It makes no network requests, stores nothing, and lets the call through if anything goes wrong. Set `ROGUEKIT_TOKEN_SAVER=off` to disable it, or `ROGUEKIT_READ_MAX_KB=300` to change the size limit. It is a guard against waste, not a compressor.

## Requirements

- Windows 10/11 with Windows PowerShell 5.1 or PowerShell 7 (`powershell` on PATH)
- [Claude Code](https://claude.com/claude-code) 2.1 or newer (`claude --version`)
- Git (to clone this repo)

## Install

### Option A: clone and run the installer (recommended)

```powershell
git clone https://github.com/RogueAssassin/roguekit.git
cd roguekit
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force   # this PowerShell window only
.\scripts\Install-RogueKit.ps1 -WhatIf     # preview, changes nothing
.\scripts\Install-RogueKit.ps1             # install
```

Then **restart Claude Code** (CLI and Desktop) and verify:

```powershell
.\scripts\Install-RogueKit.ps1 -Action Doctor
```

Keep the cloned folder: the plugin marketplace points at it. To install straight from GitHub instead, so you can delete the clone, use `-Source RogueAssassin/roguekit`.

### Option B: plugin only, no clone

Inside Claude Code:

```text
/plugin marketplace add RogueAssassin/roguekit
/plugin install roguekit@roguekit
```

This installs the skills, agents and hook but not the global rules block. Add the rules later by cloning and running `.\scripts\Install-RogueKit.ps1 -SkipPlugin`.

Use **one** install path. Do not install the plugin by hand and then run the installer's plugin step again, and do not stack RogueKit on top of other large bundles that ship the same skills.

### What the installer changes

- Adds or updates one block in `~/.claude/CLAUDE.md`, between `<!-- BEGIN ROGUEKIT MANAGED -->` and `<!-- END ROGUEKIT MANAGED -->`. Everything else in that file is left alone, and a timestamped backup goes to `~/.roguekit/backups/` first.
- Registers the `roguekit` marketplace and installs the plugin using the `claude` CLI.
- Writes `~/.roguekit/state.json`.

It never edits `settings.json`, credentials, MCP configuration or any project files, and every step honours `-WhatIf`.

### Upgrading from the earlier "ClaudePack"

Just run `.\scripts\Install-RogueKit.ps1`. It detects an old ClaudePack install, removes its files only if they are byte-for-byte unmodified (modified files are kept with a warning), uninstalls the old plugin, and replaces the old rules block in place. The old `~/ClaudeCode-Global-Pack` data folder is left for you to delete. Use `-KeepOldPack` to skip this.

## Using it

1. Work normally. Claude starts on Sonnet (set it yourself with `/model sonnet`); the rules tell it to recommend Opus only for architecture, security-sensitive reasoning, big cross-cutting refactors, or a failure that survives two distinct fix attempts.
2. For a real feature or bug, ask for `plan-and-verify`. For a design question, delegate to the `architect` agent. For a stubborn bug, use `deep-debugger`.
3. Before `/clear` or when pausing, ask for `session-handoff`; resume later by asking it to read the handoff.
4. If a session feels slow or costly, ask for `context-budget` and run `/context`.
5. If the token saver blocks a call, follow its message (ranged read, bounded command). Do not disable it to work around one denial.

### Model strategy

Sonnet is the baseline. Escalate for one hard step with the Opus agents or `/model opus`, then return with `/model sonnet`. `/model opusplan` (Opus plans, Sonnet executes) is also available. RogueKit never changes your model or settings by itself.

## Optional extras

### MCP servers (opt-in)

```powershell
.\scripts\Install-RogueKit.ps1 -McpServers context7
```

Choices: `context7` (current library docs), `playwright` (browser testing of an existing UI), `chrome-devtools` (live DOM/console/performance). They run third-party npm packages through `npx`, so **Node.js 18+ must be installed**, and each one adds tool definitions to every session. Add only what you need. Existing servers with the same name are preserved. Remove with `claude mcp remove <name>`.

### Graphify (opt-in)

```powershell
.\scripts\Install-RogueKit.ps1 -WithGraphify                  # default folder D:\UV
.\scripts\Install-RogueKit.ps1 -WithGraphify -UvDir E:\UV
```

Installs uv 0.13.7 (downloaded from the official release, SHA-256 verified), Python 3.12 and the `graphifyy` package under `-UvDir`, sets five `UV_*` user environment variables, adds `<UvDir>\bin` to your user PATH, and runs `graphify install`. It builds no graph and adds no per-project hooks. It pays off on large or unfamiliar repos; measure before enabling it widely. See the `graphify-guide` skill.

## Monthly check

```powershell
.\scripts\Install-RogueKit.ps1 -Action Audit
```

Estimates the always-on cost of your global rules, skills, plugins and MCP servers. Remove what you did not use (`claude plugin uninstall <name>`, `claude mcp remove <name>`).

## Update

```powershell
cd roguekit
git pull
.\scripts\Install-RogueKit.ps1
```

Restart Claude Code afterwards.

## Uninstall

```powershell
.\scripts\Install-RogueKit.ps1 -Action Uninstall
```

Removes the plugin, the marketplace entry and the managed rules block (with a backup). It does not remove MCP servers, Graphify/uv, or `~/.roguekit`; the command prints how to remove those.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Skills do not appear | Restart Claude Code; run `-Action Doctor` |
| `Doctor` says plugin not installed | Run the installer without `-SkipPlugin`, or use Option B |
| Rules block appears twice | Run the installer once more; if it persists, remove the extra block by hand |
| Duplicate skills listed | An old copy exists under `~/.claude/skills`; Doctor lists them. Delete the user-level copies |
| A read or `git log` was blocked | Read with `offset`/`limit`, or add `-n 20`. Temporarily: `$env:ROGUEKIT_TOKEN_SAVER='off'` |
| MCP server fails to connect | Install Node.js 18+, then `claude mcp list` |
| Script blocked by execution policy | Use the process-scoped `Set-ExecutionPolicy ... -Scope Process` line above |

## Security and privacy

- No telemetry, no network calls from the hook or installer (the optional Graphify step downloads from GitHub and PyPI, and MCP servers fetch npm packages, only when you opt in).
- All content is plain text you can read before installing: `plugin/` (skills, agents, hook) and `rules/global-rules.md`.
- Plugins and MCP servers run with your permissions. Review anything you add, including this repo.

## Repository layout

```text
.claude-plugin/marketplace.json   marketplace definition
plugin/                           the plugin (skills, agents, hooks)
rules/global-rules.md             text of the managed CLAUDE.md block
scripts/Install-RogueKit.ps1      installer, doctor, audit, uninstall
```

## Credits

Ideas for the plan/test/review/verify workflow, session handoff and the lifecycle-style installer were inspired by the MIT-licensed [ECC](https://github.com/affaan-m/ecc) project. No ECC code or content is included.

## License

MIT. See [LICENSE](LICENSE).
