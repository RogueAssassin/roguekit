# Skills reference

RogueKit ships **28 skills**. A skill's full text loads only when Claude decides it is relevant (or you invoke it by name, shown as `roguekit:<name>`). Until then only its one-line description is in context.

How to use any skill: describe the task normally, or name it ("use the dotnet-csharp skill to review this service"). Type `/` to see them. The *Example* column is a prompt that triggers it.

## Workflow and context

| Skill | Use it for | Example |
|---|---|---|
| `plan-and-verify` | Non-trivial features, fixes or refactors: plan, failing test first, implement, independent review, final verification. | "Use plan-and-verify to add retry logic to the sync service." |
| `session-handoff` | Saving a compact handoff note before `/clear` or `/compact`, and resuming from it later. Default file `.roguekit/handoff.md`. | "Write a handoff before I clear." / "Resume from the handoff." |
| `context-budget` | Finding what is eating context (instructions, skills, MCP servers, tool output) and picking the smallest fix. | "This session feels slow and expensive; run context-budget." |
| `token-efficiency` | Token-aware habits for long sessions: targeted reads, bounded output, fewer subagents. | "We have a big refactor; keep token use low." |
| `model-routing` | Deciding when to stay on Sonnet and when to escalate to Opus (or `opusplan`). | "Should this migration design be on Opus?" |
| `mcp-plugins` | Choosing, vetting, auditing and troubleshooting MCP servers and plugins. | "Which MCP server would help test this UI, and what does it cost in context?" |
| `graphify-guide` | Whether and how to use Graphify (knowledge graph) on a large codebase. | "Is Graphify worth it for this repo?" |
| `free-model-assist` | Hand small, low-risk side tasks (summaries, drafts, second opinions) to free or local model APIs with a built-in PowerShell script. Asks before sending anything. | "Get a second opinion from a free model on this error message." |
| `free-apis` | Check current package versions, vulnerabilities (OSV), end-of-life dates and GitHub releases from free public APIs, no keys. | "What's the latest Django and is 3.2.0 vulnerable?" |
| `code-map` | Build a compact map of a codebase (files, symbols, imports) and answer "where is X / what uses X / what imports this" without reading whole files. Offline, PowerShell only. | "Where is OrderService defined and what uses it?" |

## Languages and platforms

| Skill | Use it for | Example |
|---|---|---|
| `dotnet-csharp` | C#, .NET, ASP.NET Core, EF Core, Windows desktop and services. Includes `references/quality-and-performance.md`. | "Find allocation hot spots in this C# parser." |
| `java-development` | Java, Spring Boot, Maven/Gradle, Hibernate. Includes quality and performance reference. | "Fix the N+1 query in this Spring service." |
| `python-development` | Python apps, libraries, APIs, packaging, typing, tests. Includes quality and performance reference. | "Profile why this script is slow." |
| `powershell-windows` | PowerShell scripts, installers, services, registry, deployment on Windows. Includes quality and performance reference. | "Review this installer script for PS 5.1 pitfalls." |
| `frontend-ui-ux` | TypeScript/React frontends, accessibility, responsive UI. Includes quality and performance reference. | "Why does this list re-render on every keystroke?" |
| `sql-database` | Schema design, queries, migrations, indexing, transactions. Includes quality and performance reference. | "Speed up this slow report query." |
| `rust-oxide-carbon` | Facepunch Rust server plugins (Oxide/uMod, Carbon, Harmony), Oxide extensions, IDE project setup, plugin templates and review checklist. | "Write a Carbon plugin that gives a kit on first join." |
| `azure-cloud` | Azure architecture, identity, networking, IaC, monitoring, cost. | "Design a cheap staging environment on Azure." |
| `api-automation` | REST/OpenAPI, webhooks, integrations, CI/CD automation. | "Build a resilient webhook receiver." |
| `git-github-ci` | Git workflow, PRs, GitHub Actions, releases; release hygiene (version, changelog, checksums). | "Set up a release workflow with checksums." |
| `game-server-tooling` | Dedicated game server managers, SteamCMD, RCON, process lifecycle, logs. | "Add safe restart handling to the server manager." |

## Infrastructure and operations

| Skill | Use it for | Example |
|---|---|---|
| `selfhosted-containers` | Docker/Podman Compose services, Dockerfiles, `install.sh`/`update.sh`, verified updates, health checks. | "Add a rollback path to update.sh." |
| `linux-server-admin` | SSH hardening and custom ports (lockout-safe), ufw, nginx, systemd, Cloudflare tunnels, cleanup. | "Move SSH to a custom port without locking me out." |
| `php-wordpress` | PHP and WordPress themes/plugins/CRM tools, security, performance, nginx/PHP-FPM, releases. | "Audit this plugin's AJAX handlers." |
| `flutter-dart` | Flutter/Dart apps and shared packages: analysis, testing, performance, releases. | "Why does this screen jank in profile mode?" |
| `android-root-modules` | Rooted-device modules, root shell scripts, Bluetooth/power tweaks, companion apps, update feeds. | "Make this module boot-safe on Pixel devices." |

## Review

| Skill | Use it for | Example |
|---|---|---|
| `security-review` | Threat modelling, auth, input handling, secrets, dependency review. | "Security-review the new login endpoint." |
| `performance-review` | Measure-first optimisation across CPU, memory, I/O, database; links to per-language references. | "Find the bottleneck, then propose options." |

## Context cost

Always loaded: each skill's one-line description (a few tens of tokens each). Loaded on use: the `SKILL.md` body. Loaded only when a skill tells Claude to read it: files under `references/`. Run `.\scripts\Install-RogueKit.ps1 -Action Audit` for the real numbers on your machine.
