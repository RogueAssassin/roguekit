# RogueKit documentation

Everything RogueKit provides, and when to use it.

| Document | Covers |
|---|---|
| [skills.md](skills.md) | All 28 skills: what each is for, example prompts, context cost |
| [agents.md](agents.md) | The 5 agents, models, when to delegate |
| [hook-and-rules.md](hook-and-rules.md) | The token-saver hook and the global rules block in `CLAUDE.md` |
| [installer.md](installer.md) | Install, Status, Doctor, Audit, Uninstall, options, updating |
| [free-model-assist.md](free-model-assist.md) | Hand side tasks to free or local model APIs (providers, keys, safety) |
| [free-apis.md](free-apis.md) | Free public API lookups: versions, vulnerabilities, end-of-life, releases |
| [code-map.md](code-map.md) | Offline code map: find definitions, usages, imports, hubs |

## What RogueKit is made of

```text
plugin/                  the Claude Code plugin: 28 skills, 5 agents, 1 hook
rules/global-rules.md    text of the managed block added to ~/.claude/CLAUDE.md
scripts/Install-RogueKit.ps1   installer, doctor, audit, uninstall
docs/                    this documentation
```

## Which part solves which problem

| I want to... | Use |
|---|---|
| Get consistent engineering habits in every session | Global rules ([hook-and-rules.md](hook-and-rules.md)) |
| Stop wasting tokens on huge reads | Token-saver hook, `token-efficiency`, `context-budget` |
| Stay on Sonnet, escalate only when needed | `model-routing`, `architect`, `deep-debugger` |
| Work on C#, Java, Python, PowerShell, TypeScript, SQL, PHP, Flutter, Rust plugins | Language skills ([skills.md](skills.md)) |
| Keep progress across `/clear` | `session-handoff` |
| Save Claude usage on small side tasks | `free-model-assist` ([free-model-assist.md](free-model-assist.md)) |
| Check versions, vulnerabilities, EOL without guessing | `free-apis` ([free-apis.md](free-apis.md)) |
| Check my setup is healthy | `Install-RogueKit.ps1 -Action Doctor` |

## Conventions

- RogueKit never changes `settings.json`, credentials or project files, and never commits, pushes or deploys for you.
- Every part is plain text you can read before installing.
- RogueKit is an independent community project and is not affiliated with or endorsed by Anthropic.
