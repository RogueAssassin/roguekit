---
name: model-routing
description: Use when deciding whether to stay on Sonnet or escalate to Opus, or when a task is unusually hard, ambiguous, high-risk or has failed repeated attempts. Invoke explicitly with /model-routing when needed.
---
# Sonnet baseline, Opus on demand

## Stay on Sonnet (default)
- Feature work, bug fixes with a clear reproduction, refactors within one component, tests, docs, scripts, code review of normal diffs, routine Git/CI work.

## Escalate to Opus when
- Designing or reviewing architecture, data models, migrations or public API contracts.
- Debugging that survives 2 distinct fix attempts, or has no clear reproduction (races, memory leaks, heisenbugs).
- Security-sensitive reasoning (authN/authZ, injection, crypto, threat modelling).
- Large cross-cutting refactors touching many modules, or performance work needing deep reasoning about trade-offs.
- Ambiguous requirements where a wrong plan would be costly to undo.

## How to escalate cheaply
1. Prefer delegating just the hard step: `architect` (design) or `deep-debugger` (stubborn bugs) run on Opus and return a concise result.
2. Or switch with `/model opus` (or `opusplan`: Opus plans, Sonnet executes), do the hard step, then `/model sonnet`.
3. Give Opus a tight brief: goal, constraints, exact paths, what was already tried, expected concise output.
4. Return to Sonnet for implementation once the plan or root cause is established.

## Rules
- State why escalation is warranted; never switch models or edit settings.json silently.
- Do not stay on Opus for follow-up routine edits, and do not escalate for simple tasks to "be safe".
