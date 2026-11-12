---
name: token-efficiency
description: Use when planning or performing Claude Code work where context size, token usage, long sessions, tool output, repeated reads, agent fan-out or usage limits matter. Invoke explicitly with /token-efficiency when needed.
---
# Token-efficient Claude Code workflow

## Default behaviour
- Do not optimise for token count at the expense of correctness, safety, or required verification.
- Do not launch subagents by default. Use one only when the task is substantial, bounded, independently parallelisable, and the isolated result will save more main-session context than it costs.
- Never use recursive agent chains. Ask before using more than two concurrent subagents or agent teams.
- Do not repeat the same inspection, test, search or review unless new evidence justifies it.

## Inspect narrowly
- Establish repository root and working-tree state once; batch related shell commands where practical.
- Search filenames and symbols first (`rg`, `git grep`, `Get-ChildItem` with filters); read only relevant ranges.
- Exclude generated/dependency/build folders from exploration: `.git`, `node_modules`, `bin`, `obj`, `dist`, `build`, `coverage`, `.venv`, `packages`, `target`, and large binary/artifact directories unless the task explicitly concerns them.
- Never dump entire repositories, lockfiles, minified bundles, binaries, or huge logs into the conversation.
- Bound command output (`--max-count`, `Select-Object -First`, `-Tail`, targeted filters). Save bulky output to a temporary file and extract only relevant excerpts.

## Keep context useful
- Reuse findings already established in the current session; do not reread unchanged files without a reason.
- Read project instructions and the smallest relevant architecture/docs slice; avoid loading every skill or unrelated documentation.
- Give subagents a narrow objective, exact paths, constraints and expected concise output. Ask for findings and evidence, not a transcript of their exploration.
- Keep handoffs and final reports concise: decisions, changed files, verification, blockers and risks.
- At a genuine task switch, use `/clear` and start with a concise task prompt. When continuing the same task and the context is large, use `/compact` with decisions, constraints, files, tests and next steps preserved.

## Tool and verification discipline
- Batch independent read-only commands when this reduces round trips; do not batch destructive actions.
- Run the narrowest useful test first, then broader checks only when justified.
- Do not run repeated broad test suites after no relevant code changed.
- Avoid fetching the same documentation repeatedly; retain the relevant source/version and consult it again only if the question changes.
- Do not automatically retry identical failures. Diagnose the cause and change the next attempt.
- If a test or compiler failure persists across 2 consecutive attempts, stop and ask the user for context (or recommend Opus escalation per `model-routing`). Do not try a 3rd time.
- Prefer targeted edits over rewriting whole files.

## Usage review
- When asked to audit token usage, inspect available session usage data and tool-output patterns without exposing prompt contents, credentials or private data.
- Separate measured token usage from estimates. Identify repeated reads, oversized outputs, unnecessary agent fan-out, stale context and expensive repeated calls.
- Recommend the smallest reversible change first. Never silently change model, permissions, plugins, hooks or user settings.
