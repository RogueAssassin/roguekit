# Agents reference

Agents are specialists that run in their own context and report back. They keep large reads and long investigations out of your main conversation. RogueKit ships six. Claude delegates to them when the task fits, or you can ask by name ("use the code-reviewer agent on this diff").

| Agent | Model | Tools | Use it for | Do not use it for |
|---|---|---|---|---|
| `code-reviewer` | Sonnet | all | Review a diff from a fresh context: correctness, regressions, maintainability, security, tests. | Writing the change itself. |
| `ui-reviewer` | Sonnet | all | Review a page in a real browser: layout, hierarchy, interaction, states, accessibility, responsive; prioritised fixes. | Code-only review with no page to look at. |
| `debugger` | Sonnet | all | Reproduce a bug, crash, failing test or build error and find the root cause. | Intermittent races/leaks that already survived two fixes (use `deep-debugger`). |
| `architect` | **Opus** | all | Architecture, integration and migration design; pragmatic plans with trade-offs. | Routine edits. |
| `deep-debugger` | **Opus** | all | Escalation: races, memory leaks, intermittent failures, or any failure that survived 2 distinct fix attempts. Give it what was already tried. | First-line debugging. |
| `context-auditor` | Haiku | read-only (Read, Grep, Glob) | Audit oversized instructions, repeated reads, noisy output, redundant skills/plugins/MCP servers. Changes nothing. | Anything that needs edits. |

## Cost guidance

- Each agent run costs its own tokens. Do not fan out several agents for a small task; ask before launching more than two.
- Opus agents are for the single hard step. Return to Sonnet afterwards (`/model sonnet`).
- Agents always run on your Claude models. Small side tasks can be handed to free models with the `free-model-assist` skill (see [free-model-assist.md](free-model-assist.md)).
