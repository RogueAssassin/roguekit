<#
.SYNOPSIS
  Build and query a compact map of a codebase (files, symbols, imports) so you can find things without reading whole files.
.DESCRIPTION
  Needs only Windows PowerShell 5.1 or newer. No installs, no network, no background process.
  Build writes one JSON file, <project>\.roguekit\codemap.json (change with -Map). Nothing else is written.
  Symbols are found with regular expressions, not a real parser: treat results as a guide, then open the file to confirm.
  Languages: C#, Java, Python, JavaScript/TypeScript, PowerShell, Rust, Dart, PHP, Go.
.EXAMPLE
  map.ps1 -Action Build -Path E:\proj
  map.ps1 -Action Find -Path E:\proj -Name OrderService
  map.ps1 -Action Uses -Path E:\proj -Name OrderService
  map.ps1 -Action Outline -Path E:\proj -File src/Orders/OrderService.cs
  map.ps1 -Action Deps -Path E:\proj -File src/Orders/OrderService.cs
  map.ps1 -Action Hubs -Path E:\proj
  map.ps1 -Action Status -Path E:\proj
#>
param(
    [ValidateSet('Build', 'Find', 'Uses', 'Outline', 'Deps', 'Hubs', 'Status')][string]$Action = 'Status',
    [string]$Path = '.',
    [string]$Name,
    [string]$File,
    [int]$Top = 40,
    [string]$Map,
    [int]$MaxFileKB = 512
)
$ErrorActionPreference = 'Stop'
function Write-Err([string]$m) { try { [Console]::Error.WriteLine($m) } catch { Write-Error -Message $m -ErrorAction Continue } }

try { $Root = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\') } catch { Write-Err "Path not found: $Path"; exit 1 }
if (!$Map) { $Map = Join-Path $Root '.roguekit\codemap.json' }

$LangByExt = @{
    '.cs' = 'cs'; '.java' = 'java'; '.py' = 'py'; '.js' = 'js'; '.jsx' = 'js'; '.mjs' = 'js'; '.cjs' = 'js'
    '.ts' = 'js'; '.tsx' = 'js'; '.ps1' = 'ps1'; '.psm1' = 'ps1'; '.rs' = 'rs'; '.dart' = 'dart'; '.php' = 'php'; '.go' = 'go'
}
$SkipDirs = @('node_modules', '.git', 'bin', 'obj', 'dist', 'build', 'target', 'venv', '.venv', '__pycache__', 'vendor', 'packages', '.roguekit', '.next', 'coverage', '.idea', '.vs', '.dart_tool')
$Mods = '(?:(?:public|private|protected|internal|static|sealed|abstract|partial|override|virtual|async|unsafe|readonly|new|extern|final|synchronized|default)\s+)'

function New-Rule([string]$re, [string]$kind, [int]$ni, [int]$ki = 0) { return @{ re = $re; kind = $kind; ni = $ni; ki = $ki } }
$SymRules = @{
    cs   = @(
        (New-Rule '^\s*namespace\s+([\w.]+)' 'namespace' 1),
        (New-Rule ('^\s*' + $Mods + '*(class|interface|struct|enum|record)\s+(\w+)') '' 2 1),
        (New-Rule ('^\s*' + $Mods + '+[\w<>\[\],.?]+(?:\s+[\w<>\[\],.?]+)*?\s+(\w+)\s*\(') 'method' 1)
    )
    java = @(
        (New-Rule '^\s*package\s+([\w.]+)' 'namespace' 1),
        (New-Rule ('^\s*' + $Mods + '*(class|interface|enum|record)\s+(\w+)') '' 2 1),
        (New-Rule ('^\s*' + $Mods + '+[\w<>\[\],.?]+(?:\s+[\w<>\[\],.?]+)*?\s+(\w+)\s*\(') 'method' 1)
    )
    py   = @(
        (New-Rule '^\s*class\s+(\w+)' 'class' 1),
        (New-Rule '^\s*(?:async\s+)?def\s+(\w+)' 'function' 1)
    )
    js   = @(
        (New-Rule '^\s*(?:export\s+)?(?:default\s+)?(?:abstract\s+)?class\s+(\w+)' 'class' 1),
        (New-Rule '^\s*(?:export\s+)?(?:interface|type|enum)\s+(\w+)' 'type' 1),
        (New-Rule '^\s*(?:export\s+)?(?:default\s+)?(?:async\s+)?function\*?\s+(\w+)' 'function' 1),
        (New-Rule '^\s*(?:export\s+)?(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s*)?(?:\([^)]*\)|\w+)\s*(?::\s*[\w<>\[\]|, ]+)?\s*=>' 'function' 1)
    )
    ps1  = @(
        (New-Rule '^\s*(?:function|filter)\s+([\w-]+)' 'function' 1),
        (New-Rule '^\s*class\s+(\w+)' 'class' 1)
    )
    rs   = @(
        (New-Rule '^\s*(?:pub(?:\([^)]*\))?\s+)?(?:async\s+)?(?:unsafe\s+)?(fn|struct|enum|trait|mod)\s+(\w+)' '' 2 1)
    )
    dart = @(
        (New-Rule '^\s*(?:abstract\s+)?(class|mixin|enum|extension)\s+(\w+)' '' 2 1)
    )
    php  = @(
        (New-Rule '^\s*namespace\s+([\w\\]+)' 'namespace' 1),
        (New-Rule '^\s*(?:abstract\s+|final\s+)?(class|interface|trait)\s+(\w+)' '' 2 1),
        (New-Rule '^\s*(?:(?:public|private|protected|static|abstract|final)\s+)*function\s+&?(\w+)' 'function' 1)
    )
    go   = @(
        (New-Rule '^\s*func\s+(?:\([^)]*\)\s*)?(\w+)' 'function' 1),
        (New-Rule '^\s*type\s+(\w+)\s+(?:struct|interface)' 'type' 1)
    )
}
$ImpRules = @{
    cs   = @('^\s*using\s+(?:static\s+)?([\w.]+)\s*;')
    java = @('^\s*import\s+(?:static\s+)?([\w.*]+)\s*;')
    py   = @('^\s*import\s+([\w.]+)', '^\s*from\s+([\w.]+)\s+import')
    js   = @('\bfrom\s+[''"]([^''"]+)[''"]', '\brequire\(\s*[''"]([^''"]+)[''"]\s*\)', '^\s*import\s+[''"]([^''"]+)[''"]')
    ps1  = @('^\s*\.\s+[''"]?([^''"\s]+\.ps1)', '^\s*Import-Module\s+[''"]?([\w.\\/:-]+)')
    rs   = @('^\s*(?:pub\s+)?use\s+([\w:]+)')
    dart = @('^\s*import\s+[''"]([^''"]+)[''"]')
    php  = @('^\s*use\s+([\w\\]+)', '\b(?:require|include)(?:_once)?\s*\(?\s*[''"]([^''"]+)[''"]')
    go   = @('^\s*import\s+"([^"]+)"', '^\s*"([\w./-]+)"\s*$')
}

function Get-SourceFiles([string]$dir) {
    $pending = @($dir)
    while ($pending.Count -gt 0) {
        $d = $pending[0]
        $pending = @($pending | Select-Object -Skip 1)
        foreach ($i in (Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue)) {
            if ($i.PSIsContainer) {
                if ($SkipDirs -notcontains $i.Name -and !($i.Attributes -band 1024)) { $pending += $i.FullName }
            }
            elseif ($LangByExt.ContainsKey($i.Extension.ToLowerInvariant()) -and $i.Name -notmatch '\.min\.' -and $i.Length -le ($MaxFileKB * 1024)) {
                $i
            }
        }
    }
}
function Get-Rel([string]$full) { return $full.Substring($Root.Length).TrimStart('\').Replace('\', '/') }
function Get-Key([string]$imp) {
    $s = $imp -replace '\.(js|jsx|ts|tsx|mjs|cjs|ps1|psm1|dart|php|py|cs|java|rs|go)$', ''
    $s = $s -replace '^.*[./\\:]', ''
    return $s.ToLowerInvariant()
}
function Read-File([string]$full, [string]$lang) {
    $syms = @()
    $imps = @()
    $lines = @(Get-Content -LiteralPath $full -ErrorAction SilentlyContinue)
    $n = 0
    foreach ($line in $lines) {
        $n++
        if ($line.Length -gt 400 -or $line -match '^\s*(//|/\*|\*|#)') { continue }
        foreach ($re in $ImpRules[$lang]) {
            if ($line -match $re) { $imps += $Matches[1]; break }
        }
        foreach ($r in $SymRules[$lang]) {
            if ($line -match $r.re) {
                $kind = $r.kind
                if ($r.ki -gt 0) { $kind = $Matches[$r.ki] }
                $syms += @{ n = $Matches[$r.ni]; k = $kind; l = $n }
                break
            }
        }
    }
    return @{ lines = $n; syms = @($syms); imps = @($imps | Select-Object -Unique) }
}
function Load-Map {
    if (!(Test-Path -LiteralPath $Map)) { Write-Err "No map yet. Run: map.ps1 -Action Build -Path $Root"; exit 2 }
    return (Get-Content -LiteralPath $Map -Raw | ConvertFrom-Json)
}
function Match-Name($sym, [string]$q) { return ($sym.n -like $q) -or ($sym.n -like "*$q*") }

switch ($Action) {
    'Build' {
        $old = @{}
        if (Test-Path -LiteralPath $Map) {
            try { foreach ($f in @((Get-Content -LiteralPath $Map -Raw | ConvertFrom-Json).files)) { $old[$f.p] = $f } } catch { $old = @{} }
        }
        $out = @()
        $reused = 0; $scanned = 0
        foreach ($fi in (Get-SourceFiles $Root)) {
            $rel = Get-Rel $fi.FullName
            $stamp = "$($fi.Length):$($fi.LastWriteTimeUtc.Ticks)"
            $lang = $LangByExt[$fi.Extension.ToLowerInvariant()]
            if ($old.ContainsKey($rel) -and $old[$rel].m -eq $stamp) { $out += $old[$rel]; $reused++; continue }
            $r = Read-File $fi.FullName $lang
            $out += @{ p = $rel; m = $stamp; g = $lang; n = $r.lines; s = $r.syms; i = $r.imps }
            $scanned++
        }
        $dir = Split-Path -Parent $Map
        if (!(Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $doc = @{ version = 1; root = $Root; built = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); files = @($out | Sort-Object { $_.p }) }
        ConvertTo-Json -InputObject $doc -Depth 6 -Compress | Set-Content -LiteralPath $Map -Encoding UTF8
        $symCount = 0; foreach ($f in $out) { $symCount += @($f.s).Count }
        "Map built: $($out.Count) files ($scanned scanned, $reused unchanged), $symCount symbols"
        "Saved to $Map"
    }
    'Status' {
        if (!(Test-Path -LiteralPath $Map)) { "No map at $Map. Run: map.ps1 -Action Build -Path $Root"; break }
        $m = Load-Map
        $files = @($m.files)
        $sc = 0; foreach ($f in $files) { $sc += @($f.s).Count }
        "Map: $Map"
        "Built: $($m.built); $($files.Count) files, $sc symbols"
        ($files | Group-Object g | Sort-Object Count -Descending | ForEach-Object { "$($_.Name): $($_.Count)" }) -join '  '
        $stale = 0
        foreach ($f in $files) {
            $p = Join-Path $Root $f.p.Replace('/', '\')
            if (!(Test-Path -LiteralPath $p)) { $stale++; continue }
            $fi = Get-Item -LiteralPath $p
            if ("$($fi.Length):$($fi.LastWriteTimeUtc.Ticks)" -ne $f.m) { $stale++ }
        }
        if ($stale -gt 0) { "$stale file(s) changed or removed since the build: run -Action Build to refresh." } else { 'Map is current.' }
    }
    'Find' {
        if (!$Name) { Write-Err 'Find needs -Name'; exit 1 }
        $m = Load-Map; $hits = @()
        foreach ($f in @($m.files)) { foreach ($s in @($f.s)) { if (Match-Name $s $Name) { $hits += "$($f.p):$($s.l)  $($s.k) $($s.n)" } } }
        if ($hits.Count -eq 0) { "No symbol matching '$Name'. The map is regex-based; try -Action Uses, or grep."; break }
        $hits | Select-Object -First $Top
        if ($hits.Count -gt $Top) { "... $($hits.Count - $Top) more (raise -Top)" }
    }
    'Outline' {
        if (!$File) { Write-Err 'Outline needs -File'; exit 1 }
        $m = Load-Map; $q = $File.Replace('\', '/')
        $f = @($m.files) | Where-Object { $_.p -eq $q -or $_.p -like "*/$q" -or $_.p -like "*$q" } | Select-Object -First 1
        if (!$f) { "File not in map: $File"; break }
        "$($f.p)  [$($f.g), $($f.n) lines]"
        foreach ($s in @($f.s)) { "  $($s.l)  $($s.k) $($s.n)" }
    }
    'Uses' {
        if (!$Name) { Write-Err 'Uses needs -Name'; exit 1 }
        $m = Load-Map
        $paths = @(@($m.files) | ForEach-Object { Join-Path $Root $_.p.Replace('/', '\') } | Where-Object { Test-Path -LiteralPath $_ })
        if ($paths.Count -eq 0) { 'No mapped files exist on disk. Rebuild the map.'; break }
        $hits = @(Select-String -LiteralPath $paths -Pattern ('\b' + [regex]::Escape($Name) + '\b') -CaseSensitive)
        if ($hits.Count -eq 0) { "No references to '$Name' in mapped files."; break }
        "$($hits.Count) reference(s) in $(@($hits | Select-Object -ExpandProperty Path -Unique).Count) file(s):"
        $hits | Select-Object -First $Top | ForEach-Object { "$(Get-Rel $_.Path):$($_.LineNumber)  $($_.Line.Trim())" }
        if ($hits.Count -gt $Top) { "... $($hits.Count - $Top) more (raise -Top)" }
    }
    'Deps' {
        if (!$File) { Write-Err 'Deps needs -File'; exit 1 }
        $m = Load-Map; $q = $File.Replace('\', '/')
        $f = @($m.files) | Where-Object { $_.p -eq $q -or $_.p -like "*/$q" -or $_.p -like "*$q" } | Select-Object -First 1
        if (!$f) { "File not in map: $File"; break }
        "$($f.p) imports:"
        foreach ($i in @($f.i)) { "  $i" }
        $base = Get-Key $f.p
        $ns = @(@($f.s) | Where-Object { $_.k -eq 'namespace' } | ForEach-Object { $_.n })
        $by = @()
        foreach ($o in @($m.files)) {
            if ($o.p -eq $f.p) { continue }
            foreach ($i in @($o.i)) {
                if ((Get-Key $i) -eq $base -or ($ns -contains $i)) { $by += $o.p; break }
            }
        }
        "imported by (name or namespace match, approximate): $($by.Count)"
        $by | Select-Object -First $Top | ForEach-Object { "  $_" }
    }
    'Hubs' {
        $m = Load-Map; $count = @{}
        foreach ($f in @($m.files)) { foreach ($i in @($f.i)) { if ($count.ContainsKey($i)) { $count[$i]++ } else { $count[$i] = 1 } } }
        'Most-imported modules (project and external):'
        $rows = @(foreach ($k in $count.Keys) { '{0:D6}  {1}' -f $count[$k], $k })
        $rows | Sort-Object -Descending | Select-Object -First 15 | ForEach-Object { '  ' + ($_ -replace '^0+(?=\d)', '') }
        ''
        'Files with the most symbols:'
        @($m.files) | Sort-Object { @($_.s).Count } -Descending | Select-Object -First 10 | ForEach-Object { "  {0,4}  {1}" -f @($_.s).Count, $_.p }
    }
}
