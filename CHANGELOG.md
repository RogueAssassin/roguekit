# Changelog

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
