---
name: code-map
description: Use on a large or unfamiliar codebase to find definitions, usages, file outlines and import relationships cheaply before reading files. Built-in PowerShell tool, no installs, no network.
---
# Code map

`scripts/map.ps1` (in this skill's folder) builds a compact map of a project (files, symbols, imports) and answers questions from it, so you read a few lines instead of whole files. Windows PowerShell 5.1 or `pwsh` only: nothing to install, no network, no background process. Run it as `powershell -NoProfile -File <skill dir>/scripts/map.ps1 -Action <Action> -Path <project root> ...`.

## When to use
- A repository is large or new to you and you need to locate code: use the map before wide grep or reading directories.
- Before a rename or API change: find the definition, then list usages.
- Judging impact: what a file imports, what imports it, and which modules are most depended on.

Skip it for small projects, single files, or when you already know where to look.

## Commands
```powershell
map.ps1 -Action Build   -Path E:\proj                       # first time, and after large changes (incremental)
map.ps1 -Action Status  -Path E:\proj                       # file counts and whether the map is stale
map.ps1 -Action Find    -Path E:\proj -Name OrderService    # symbol definitions (substring match, file:line)
map.ps1 -Action Uses    -Path E:\proj -Name OrderService    # whole-word references with file:line
map.ps1 -Action Outline -Path E:\proj -File src/Orders/OrderService.cs
map.ps1 -Action Deps    -Path E:\proj -File src/Orders/OrderService.cs   # imports, and files that import it
map.ps1 -Action Hubs    -Path E:\proj                       # most-imported modules, files with most symbols
```
`-Top N` limits output. Languages: C#, Java, Python, JavaScript/TypeScript, PowerShell, Rust, Dart, PHP, Go. Skipped folders: node_modules, .git, bin, obj, dist, build, target, venv, vendor, packages and similar.

## Rules
- **It writes one file**, `<project>\.roguekit\codemap.json`, inside the project. Tell the user the first time, and suggest adding `.roguekit/` to `.gitignore`. Do not commit it.
- **Regex, not a parser.** Symbols can be missed (for example interface methods without modifiers, generated code) or misread. Treat results as a pointer, then open the file at that line to confirm before editing. If `Find` finds nothing, fall back to `Uses` or grep.
- `Deps` "imported by" is approximate (matches by file name or namespace).
- Check `Status` before trusting a map from earlier in the session; rebuild if it reports changed files.
- The map never leaves the machine. Do not paste it wholesale into prompts or send it to other services.

More: `docs/code-map.md` in the RogueKit repository.
