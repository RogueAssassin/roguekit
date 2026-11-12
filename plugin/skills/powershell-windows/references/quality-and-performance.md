# PowerShell / Windows: error prevention and performance alternatives

Target Windows PowerShell 5.1 unless the repo clearly requires 7+. Check `$PSVersionTable` before using 7-only syntax (`&&`, `??`, `ForEach-Object -Parallel`, ternary).

## Catch errors early
1. Parse check without running: `[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errs)`; print `$errs`.
2. `Invoke-ScriptAnalyzer -Path <file> -Severity Warning,Error` (PSScriptAnalyzer) if installed.
3. `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` in new scripts; `[CmdletBinding(SupportsShouldProcess)]` with `-WhatIf` for anything that changes state.
4. Pester for logic (`Invoke-Pester`), run read-only/`-WhatIf` first, then the real run only with approval.
5. Encoding: UTF-8 with BOM for scripts containing non-ASCII on 5.1; ASCII-only is safest.

Pitfalls: native-command stderr under `Stop` (wrap with `$ErrorActionPreference='Continue'` locally), `$LASTEXITCODE` ignored, unquoted paths with spaces, `-and` with command calls without parentheses, `Out-Null` hiding errors, `+=` on arrays, case-insensitive compares, `Join-Path` on missing drives, `Invoke-WebRequest` `.Content` being `byte[]` for some types, `Remove-Item -Recurse` on a computed path (validate first), here-string terminators not at column 0.

## Measure first
`Measure-Command { ... }` over several runs with realistic data; compare medians, not the first run (JIT, disk cache).

## Alternatives to try
| Problem | Alternatives |
|---|---|
| Array growth with `+=` | `[System.Collections.Generic.List[object]]` or assign the loop output: `$r = foreach (...) { ... }` |
| String concatenation in loops | `[System.Text.StringBuilder]`, `-join` |
| `Where-Object`/`ForEach-Object` on big sets | `foreach` statement, `.Where()`/`.ForEach()` methods, filter at the source |
| Slow file enumeration | `Get-ChildItem -Filter` (not `-Include`), `[System.IO.Directory]::EnumerateFiles`, limit `-Depth` |
| Large file reads | `Get-Content -Raw`, `[System.IO.File]::ReadLines`/`ReadAllText`, `-ReadCount 1000` |
| Repeated remote/process calls | Batch into one call; `Invoke-Command` with arrays; cache results |
| Independent slow tasks | `ForEach-Object -Parallel` (7+), `Start-ThreadJob` (limit throttle) |
| Many registry/WMI queries | `Get-CimInstance` with `-Filter` and `-Property`; avoid `Get-WmiObject` |
| Pipeline overhead in hot loops | Call .NET methods directly; avoid `Select-Object` per item |

Rules: keep scripts idempotent, support `-WhatIf`, never delete or overwrite without checking the target, and do not use `Invoke-Expression` on untrusted input.
