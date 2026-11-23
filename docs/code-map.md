# code-map

A built-in, offline alternative to knowledge-graph tools for navigating large codebases. It needs only the Windows PowerShell that ships with Windows: no Python, Node, uv, downloads or network access.

## What it does
`scripts/map.ps1` scans a project and writes one JSON file, `<project>\.roguekit\codemap.json`, listing for every source file its symbols (namespaces, classes, interfaces, functions, methods with line numbers) and its imports. Queries read that file, so Claude gets a few lines of answer instead of reading whole files.

| Action | Answers |
|---|---|
| `Build` | Creates or refreshes the map. Incremental: unchanged files (same size and timestamp) are reused. |
| `Status` | File and symbol counts, languages, and whether files changed since the build. |
| `Find -Name X` | Where symbols matching X are defined. |
| `Uses -Name X` | Whole-word, case-sensitive references to X across mapped files. |
| `Outline -File F` | Symbols in one file. |
| `Deps -File F` | What F imports, and which files import it (approximate). |
| `Hubs` | Most-imported modules, and files with the most symbols. |

Languages: C#, Java, Python, JavaScript/TypeScript, PowerShell, Rust, Dart, PHP, Go. Folders such as `node_modules`, `.git`, `bin`, `obj`, `dist`, `build`, `target`, `venv`, `vendor` and `packages` are skipped, as are minified files and files over 512 KB (`-MaxFileKB`).

## Limits compared with Graphify
- Symbols come from regular expressions, not a syntax tree: some are missed or misread. Use results as pointers and confirm in the file.
- No documents, images, video or semantic summaries, and no graph clustering.
- Large repositories scan more slowly than a native parser. The first build is the slow one.

## Privacy and safety
- Writes only the map file inside the project (change with `-Map`). Add `.roguekit/` to `.gitignore`.
- No network, no child processes, no installs. Works in PowerShell Constrained Language Mode.
- On managed devices see [managed-devices.md](managed-devices.md).

## Example
```powershell
powershell -NoProfile -File map.ps1 -Action Build -Path E:\proj
powershell -NoProfile -File map.ps1 -Action Find  -Path E:\proj -Name Order
powershell -NoProfile -File map.ps1 -Action Uses  -Path E:\proj -Name OrderService
```
