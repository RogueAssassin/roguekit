---
name: graphify-guide
description: Use when deciding whether and how to use Graphify (the /graphify knowledge-graph skill) to cut token use on a large or unfamiliar codebase, or when it is being installed, updated or removed. Invoke explicitly with /graphify-guide when needed.
---
# Graphify guidance

Graphify maps a project into a queryable graph (`graphify-out/graph.json`, `GRAPH_REPORT.md`, `graph.html`). It maps files, not chat history; conversation memory is a separate concern (Claude memory, project notes).

## When it helps
- Large or unfamiliar repos (hundreds of files), cross-file questions ("what connects X to Y?"), architecture overviews.
- Skip it for small repos or single-file edits: the graph overhead can cost more tokens than it saves. Measure on a real task before enabling widely.

## How to use
- Build once per project with `/graphify .`; refresh with `/graphify . --update` or `graphify update .`.
- Query instead of grepping broadly: `graphify query "<question>"`, `graphify path A B`, `graphify explain X`. Read `GRAPH_REPORT.md` only for broad architecture review.
- Edges are tagged EXTRACTED (explicit in source) or INFERRED; verify INFERRED links in the code before relying on them.

## Rules
- Code parsing is local (tree-sitter). Docs, PDFs, images and video use a model for a semantic pass: ask the user before running that on private or large content, and note it may spend tokens or send content to the configured backend.
- Do not run `graphify claude install` (per-project hook and instructions), `graphify hook install` (git hooks) or any Cloud sign-up without the user's approval for that repo.
- Add `graphify-out/` to `.gitignore` unless the user wants the graph committed.
- Tools live under the user's uv folder (the folder chosen at install, e.g. `D:\UV`, env `UV_*`). Update: `uv tool upgrade graphifyy`. Remove: `graphify uninstall`, then `uv tool uninstall graphifyy`.
