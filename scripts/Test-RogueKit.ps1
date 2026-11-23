<#
.SYNOPSIS
  Self-test for the RogueKit repository. Needs only Windows PowerShell 5.1 or newer.
.DESCRIPTION
  Offline by default: no internet, no API keys, no changes to your machine. Temporary files go to the
  temp folder, saved-key tests use a throw-away ROGUEKIT_HOME, and the fake model provider listens on
  127.0.0.1 only for the duration of the run.
  -Action Test      (default) run all checks; exit code 1 if any fail
  -Action Manifest  print SHA-256 and size of every file, for review or allow-listing by IT
  -Online           also run live lookups against public APIs (npm registry, OSV)
.EXAMPLE
  powershell -File scripts/Test-RogueKit.ps1
  powershell -File scripts/Test-RogueKit.ps1 -Action Manifest > manifest.txt
#>
[CmdletBinding()]
param(
    [ValidateSet('Test', 'Manifest')][string]$Action = 'Test',
    [switch]$Online
)
$ErrorActionPreference = 'Continue'
$Repo = Split-Path -Parent $PSScriptRoot
$Plugin = Join-Path $Repo 'plugin'
$Hook = Join-Path $Plugin 'hooks\token-guard.ps1'
$Ask = Join-Path $Plugin 'skills\free-model-assist\scripts\ask-free.ps1'
$Lookup = Join-Path $Plugin 'skills\free-apis\scripts\lookup.ps1'

if ($Action -eq 'Manifest') {
    Get-ChildItem -LiteralPath $Repo -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
        Sort-Object FullName |
        ForEach-Object {
            $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $rel = $_.FullName.Substring($Repo.Length + 1).Replace('\', '/')
            '{0}  {1,8}  {2}' -f $h, $_.Length, $rel
        }
    return
}

$script:fail = 0
$script:pass = 0
function Check([string]$Name, [bool]$Ok, [string]$Detail = '') {
    if ($Ok) { $script:pass++; Write-Host "[PASS] $Name" }
    else { $script:fail++; Write-Host "[FAIL] $Name $Detail" }
}
function Section([string]$t) { Write-Host ''; Write-Host "== $t" }
function Read-Text([string]$p) { return [System.IO.File]::ReadAllText($p) }
function Frontmatter([string]$text, [string]$key) {
    if ($text -match "(?m)^$key\s*:\s*(.+?)\s*$") { return $Matches[1].Trim() }
    return ''
}

# --------------------------------------------------------------------------------------------------
Section 'Structure'
$skillDirs = @(Get-ChildItem -LiteralPath (Join-Path $Plugin 'skills') -Directory)
$agentFiles = @(Get-ChildItem -LiteralPath (Join-Path $Plugin 'agents') -Filter *.md -File)

foreach ($f in '.claude-plugin\marketplace.json', 'plugin\.claude-plugin\plugin.json', 'plugin\hooks\hooks.json') {
    $ok = $true
    try { [void](Get-Content -LiteralPath (Join-Path $Repo $f) -Raw | ConvertFrom-Json) } catch { $ok = $false }
    Check "valid JSON: $f" $ok
}
$ver = (Get-Content -LiteralPath (Join-Path $Plugin '.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version
$top = if ((Read-Text (Join-Path $Repo 'CHANGELOG.md')) -match '(?m)^##\s+(\d+\.\d+\.\d+)') { $Matches[1] } else { '' }
Check "plugin version $ver matches top CHANGELOG entry ($top)" ($ver -eq $top)

foreach ($d in $skillDirs) {
    $md = Join-Path $d.FullName 'SKILL.md'
    if (!(Test-Path -LiteralPath $md)) { Check "skill $($d.Name) has SKILL.md" $false; continue }
    $t = Read-Text $md
    $nm = Frontmatter $t 'name'
    $ds = Frontmatter $t 'description'
    Check "skill $($d.Name): name matches folder" ($nm -eq $d.Name) "(name is '$nm')"
    Check "skill $($d.Name): description present and under 500 chars" (($ds.Length -gt 20) -and ($ds.Length -le 500)) "(length $($ds.Length))"
}
foreach ($a in $agentFiles) {
    $t = Read-Text $a.FullName
    Check "agent $($a.BaseName): name and description" ((Frontmatter $t 'name') -ne '' -and (Frontmatter $t 'description') -ne '')
}

$skillsDoc = Read-Text (Join-Path $Repo 'docs\skills.md')
$missing = @($skillDirs | Where-Object { $skillsDoc -notmatch ('`' + [regex]::Escape($_.Name) + '`') } | ForEach-Object { $_.Name })
Check 'docs/skills.md lists every skill' ($missing.Count -eq 0) ("(missing: " + ($missing -join ', ') + ')')
$n = $skillDirs.Count
Check "docs/skills.md says $n skills" ($skillsDoc -match "ships \*\*$n skills\*\*")
Check "README says $n skills" ((Read-Text (Join-Path $Repo 'README.md')) -match "\b$n skills\b")
Check "docs/README.md says $n skills" ((Read-Text (Join-Path $Repo 'docs\README.md')) -match "\b$n skills\b")

# --------------------------------------------------------------------------------------------------
Section 'Scripts parse'
$ps1 = @(Get-ChildItem -LiteralPath $Repo -Recurse -Filter *.ps1 -File | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
foreach ($f in $ps1) {
    $perr = $null; $ptok = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$ptok, [ref]$perr)
    Check "parses: $($f.FullName.Substring($Repo.Length + 1))" (!$perr -or $perr.Count -eq 0)
}

# --------------------------------------------------------------------------------------------------
Section 'Managed-device hygiene (patterns that endpoint-protection tools commonly flag)'
$flagged = @(
    @('Invoke-Expression / iex', '(?i)\bInvoke-Expression\b|(?<![\w-])iex\s'),
    @('encoded command', '(?i)-EncodedCommand|\s-enc\s'),
    @('download cradle', '(?i)DownloadString|DownloadFile|Net\.WebClient'),
    @('base64 decode', '(?i)FromBase64String'),
    @('hidden window', '(?i)-WindowStyle\s+Hidden'),
    @('execution-policy bypass', '(?i)-ExecutionPolicy\s+Bypass|Set-ExecutionPolicy'),
    @('runtime code generation', '(?i)\bAdd-Type\b|Reflection\.Emit|Assembly\]::Load|VirtualAlloc')
)
$shipped = @(Get-ChildItem -LiteralPath (Join-Path $Repo 'plugin'), (Join-Path $Repo 'scripts') -Recurse -File |
        Where-Object { $_.Extension -in '.ps1', '.json', '.md' -and $_.Name -ne 'Test-RogueKit.ps1' })
foreach ($rule in $flagged) {
    $hits = @($shipped | Where-Object { (Read-Text $_.FullName) -match $rule[1] } | ForEach-Object { $_.Name })
    # Skill/docs text may *mention* a pattern to forbid it; only code and config are checked strictly.
    $codeHits = @($shipped | Where-Object { $_.Extension -in '.ps1', '.json' -and (Read-Text $_.FullName) -match $rule[1] } | ForEach-Object { $_.Name })
    Check ("no " + $rule[0] + " in shipped scripts or config") ($codeHits.Count -eq 0) ("(found in: " + ($codeHits -join ', ') + ')')
}

Section 'Secrets and attribution scan'
$secretRules = @('-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----', 'AKIA[0-9A-Z]{16}', 'gh[pousr]_[A-Za-z0-9]{36}', 'sk-[A-Za-z0-9]{32,}', 'AIza[0-9A-Za-z_-]{35}', 'gsk_[A-Za-z0-9]{30,}', 'xox[baprs]-[A-Za-z0-9-]{20,}')
$attr = @(('Co-Authored' + '-By'), ('Generated ' + 'with'), ('noreply@' + 'anthropic'))
$allText = @(Get-ChildItem -LiteralPath $Repo -Recurse -File -Force | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.Length -lt 2MB -and $_.Extension -notin '.png', '.jpg', '.zip' })
$secretHits = @(); $attrHits = @()
foreach ($f in $allText) {
    $t = Read-Text $f.FullName
    foreach ($r in $secretRules) { if ($t -match $r) { $secretHits += $f.Name } }
    foreach ($r in $attr) { if ($t.IndexOf($r, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and $f.Name -ne 'Test-RogueKit.ps1') { $attrHits += $f.Name } }
}
Check 'no secrets or private keys in the repository' ($secretHits.Count -eq 0) ("(" + ($secretHits -join ', ') + ')')
Check 'no tool-attribution trailers in the repository' ($attrHits.Count -eq 0) ("(" + ($attrHits -join ', ') + ')')

# --------------------------------------------------------------------------------------------------
Section 'Token-saver hook (full language mode, run as hooks.json runs it)'
function Invoke-HookCase([string]$Json, [bool]$Clm) {
    if ($Clm) {
        $cmd = '$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"; $input | & "' + $Hook + '"'
        return ($Json | powershell -NoProfile -NonInteractive -Command $cmd 2>&1 | Out-String)
    }
    return ($Json | powershell -NoProfile -NonInteractive -File $Hook 2>&1 | Out-String)
}
$bigFile = Join-Path ([System.IO.Path]::GetTempPath()) ('rk_big_' + [guid]::NewGuid().ToString('N') + '.txt')
Set-Content -LiteralPath $bigFile -Value ('x' * 400000)
$bigJson = '{"tool_name":"Read","tool_input":{"file_path":"' + $bigFile.Replace('\', '/') + '"}}'
$hookCases = @(
    @('denies bare git log', '{"tool_name":"Bash","tool_input":{"command":"git log"}}', $true),
    @('allows bounded git log', '{"tool_name":"Bash","tool_input":{"command":"git log -n 5 --oneline"}}', $false),
    @('denies lockfile read', '{"tool_name":"Read","tool_input":{"file_path":"C:/x/package-lock.json"}}', $true),
    @('allows ranged lockfile read', '{"tool_name":"Read","tool_input":{"file_path":"C:/x/package-lock.json","limit":50}}', $false),
    @('denies node_modules read', '{"tool_name":"Read","tool_input":{"file_path":"C:/x/node_modules/a/b.js"}}', $true),
    @('denies oversized file', $bigJson, $true),
    @('fails open on garbage', 'not json at all', $false),
    @('fails open on empty input', '', $false)
)
foreach ($clm in $false, $true) {
    $mode = if ($clm) { 'constrained language' } else { 'full language' }
    foreach ($c in $hookCases) {
        $o = Invoke-HookCase $c[1] $clm
        Check ("hook ($mode): " + $c[0]) (([bool]($o -match '"deny"')) -eq $c[2])
    }
}
$env:ROGUEKIT_TOKEN_SAVER = 'off'
Check 'hook: off switch allows everything' (!((Invoke-HookCase $hookCases[0][1] $false) -match '"deny"'))
Remove-Item Env:\ROGUEKIT_TOKEN_SAVER -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $bigFile -Force -ErrorAction SilentlyContinue

# --------------------------------------------------------------------------------------------------
Section 'ask-free.ps1 against a fake local provider'
$tmpHome = Join-Path ([System.IO.Path]::GetTempPath()) ('rk_home_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpHome | Out-Null
$savedEnv = @{}
foreach ($v in 'ROGUEKIT_HOME', 'ROGUEKIT_OFFLINE', 'GROQ_API_KEY', 'CUSTOM_API_KEY') { $savedEnv[$v] = [Environment]::GetEnvironmentVariable($v) }
$env:ROGUEKIT_HOME = $tmpHome
Remove-Item Env:\ROGUEKIT_OFFLINE, Env:\GROQ_API_KEY, Env:\CUSTOM_API_KEY -ErrorAction SilentlyContinue

$tcp = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
$tcp.Start(); $port = $tcp.LocalEndpoint.Port; $tcp.Stop()
$stubJob = Start-Job -ArgumentList $port -ScriptBlock {
    param($port)
    $l = New-Object System.Net.HttpListener
    $l.Prefixes.Add("http://127.0.0.1:$port/")
    $l.Start()
    while ($l.IsListening) {
        $ctx = $l.GetContext(); $req = $ctx.Request; $res = $ctx.Response
        $body = ''
        if ($req.HasEntityBody) { $sr = New-Object System.IO.StreamReader($req.InputStream, [System.Text.Encoding]::UTF8); $body = $sr.ReadToEnd(); $sr.Close() }
        $path = $req.Url.AbsolutePath; $code = 200; $out = ''; $stop = $false
        if ($path -eq '/quit') { $out = 'bye'; $stop = $true }
        elseif ($path -eq '/health') { $out = 'ok' }
        elseif ($req.HttpMethod -eq 'GET' -and $path -like '*/models') { $out = '{"data":[{"id":"model-b"},{"id":"model-a:free"}]}' }
        else {
            $j = $body | ConvertFrom-Json
            if ($j.model -eq 'limited') { $code = 429; $out = '{"error":{"message":"slow"}}' }
            else {
                $auth = $req.Headers['Authorization']; if (!$auth) { $auth = 'none' }
                $msg = $j.messages[$j.messages.Count - 1].content
                $out = (@{ choices = @(@{ message = @{ content = "echo: $msg | auth=$auth" } }) } | ConvertTo-Json -Depth 6 -Compress)
            }
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($out)
        $res.StatusCode = $code; $res.ContentType = 'application/json'; $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length); $res.OutputStream.Close()
        if ($stop) { $l.Stop() }
    }
}
$base = "http://127.0.0.1:$port/v1"
$ready = $false
for ($i = 0; $i -lt 40 -and !$ready; $i++) {
    Start-Sleep -Milliseconds 250
    try { $ready = ((Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/health" -TimeoutSec 2).Content -eq 'ok') } catch { $ready = $false }
}
Check 'fake provider started' $ready

if ($ready) {
    function Ask([string[]]$AskArgs) { $o = (powershell -NoProfile -NonInteractive -File $Ask @AskArgs 2>&1 | Out-String); return [PSCustomObject]@{ Text = $o; Code = $LASTEXITCODE } }

    $r = Ask @('-BaseUrl', $base, '-Target', 'custom/good', '-Prompt', 'hello world')
    Check 'ask returns the model reply' ($r.Text -match 'echo: hello world' -and $r.Code -eq 0)
    Check 'no key means no Authorization header sent to a local provider' ($r.Text -match 'auth=none')

    $r = Ask @('-BaseUrl', $base, '-Target', 'custom/limited,custom/good', '-Retries', '0', '-Prompt', 'second')
    Check 'falls back to the next target after HTTP 429' ($r.Text -match 'echo: second' -and $r.Text -match 'HTTP 429')

    $r = Ask @('-Action', 'ListModels', '-Provider', 'custom', '-BaseUrl', $base, '-Filter', 'free')
    Check 'ListModels with filter' ($r.Text -match 'custom/model-a:free' -and $r.Text -notmatch 'model-b')

    $r = (('from pipe') | powershell -NoProfile -NonInteractive -File $Ask -BaseUrl $base -Target custom/good 2>&1 | Out-String)
    Check 'reads the prompt from the pipeline' ($r -match 'echo: from pipe')

    $r = Ask @('-BaseUrl', $base, '-Target', 'custom/good', '-Prompt', ('password = ' + 'abcdefgh12345678'))
    Check 'refuses text that looks like a secret' ($r.Code -eq 1 -and $r.Text -match 'secret' -and $r.Text -notmatch 'echo:')

    $r = Ask @('-BaseUrl', $base, '-Target', 'custom/good', '-Prompt', 'x', '-DryRun')
    Check 'dry run sends nothing' ($r.Text -match 'nothing was sent' -and $r.Code -eq 0)

    $r = Ask @('-BaseUrl', 'http://example.com/v1', '-Target', 'custom/good', '-Prompt', 'x')
    Check 'refuses plain HTTP to a remote host' ($r.Code -eq 1 -and $r.Text -match 'HTTPS')

    $r = Ask @('-Target', 'groq/some-model', '-Prompt', 'x')
    Check 'reports a missing key without contacting anything' ($r.Code -eq 1 -and $r.Text -match 'No key for groq')

    # Saved key (DPAPI) round trip, in the throw-away home
    $kd = Join-Path $tmpHome 'keys'; New-Item -ItemType Directory -Path $kd -Force | Out-Null
    ConvertFrom-SecureString (ConvertTo-SecureString 'test-key-123' -AsPlainText -Force) | Set-Content -LiteralPath (Join-Path $kd 'custom.key') -Encoding ASCII
    $r = Ask @('-BaseUrl', $base, '-Target', 'custom/good', '-Prompt', 'k')
    Check 'uses an encrypted saved key as a Bearer token' ($r.Text -match 'auth=Bearer test-key-123')
    $r = Ask @('-Action', 'Status')
    Check 'Status shows key source but never the key' ($r.Text -match 'saved key' -and $r.Text -notmatch 'test-key-123')

    # Offline switch
    $env:ROGUEKIT_OFFLINE = '1'
    $r = Ask @('-Target', 'groq/some-model', '-Prompt', 'x')
    Check 'ROGUEKIT_OFFLINE blocks remote providers' ($r.Code -eq 1 -and $r.Text -match 'OFFLINE')
    $r = Ask @('-BaseUrl', $base, '-Target', 'custom/good', '-Prompt', 'local ok')
    Check 'ROGUEKIT_OFFLINE still allows localhost model servers' ($r.Text -match 'echo: local ok')
    $r = (powershell -NoProfile -NonInteractive -File $Lookup -Kind Package -Ecosystem npm -Name express 2>&1 | Out-String)
    Check 'ROGUEKIT_OFFLINE disables public API lookups (exit 3)' ($LASTEXITCODE -eq 3 -and $r -match 'OFFLINE')
    Remove-Item Env:\ROGUEKIT_OFFLINE -ErrorAction SilentlyContinue

    # Constrained language mode
    $clmCmd = '$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"; & "' + $Ask + '" -Action Status'
    $r = (powershell -NoProfile -NonInteractive -Command $clmCmd 2>&1 | Out-String)
    Check 'ask-free Status works in constrained language mode' ($r -match 'Providers' -and $r -notmatch 'Cannot invoke method')
    $clmCmd = '$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"; & "' + $Ask + '" -BaseUrl "' + $base + '" -Target custom/good -Prompt clm'
    $r = (powershell -NoProfile -NonInteractive -Command $clmCmd 2>&1 | Out-String)
    Check 'ask-free works in constrained language mode' ($r -match 'echo: clm')
}
try { [void](Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$port/quit" -TimeoutSec 3) } catch { }
Start-Sleep -Milliseconds 300
Stop-Job -Job $stubJob -ErrorAction SilentlyContinue; Remove-Job -Job $stubJob -Force -ErrorAction SilentlyContinue
foreach ($k in $savedEnv.Keys) { if ($null -eq $savedEnv[$k]) { Remove-Item "Env:\$k" -ErrorAction SilentlyContinue } else { Set-Item "Env:\$k" $savedEnv[$k] } }
Remove-Item -LiteralPath $tmpHome -Recurse -Force -ErrorAction SilentlyContinue

# --------------------------------------------------------------------------------------------------
Section 'code-map (map.ps1) on a temporary sample project'
$MapScript = Join-Path $Plugin 'skills\code-map\scripts\map.ps1'
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ('rk_proj_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $proj 'src'), (Join-Path $proj 'web'), (Join-Path $proj 'node_modules\x') | Out-Null
Set-Content -LiteralPath (Join-Path $proj 'src\OrderService.cs') -Value @('using System;', 'using MyApp.Data;', 'namespace MyApp.Orders', '{', '    public class OrderService : IOrderService', '    {', '        public async Task<Order> GetOrderAsync(int id) { return null; }', '    }', '}')
Set-Content -LiteralPath (Join-Path $proj 'src\Caller.cs') -Value @('using MyApp.Orders;', 'public class Caller { void Run() { var s = new OrderService(); } }')
Set-Content -LiteralPath (Join-Path $proj 'web\app.js') -Value @("import { util } from './util.js';", 'export function render() {}')
Set-Content -LiteralPath (Join-Path $proj 'web\util.js') -Value @('export const util = (a) => a;')
Set-Content -LiteralPath (Join-Path $proj 'tool.py') -Value @('import os', 'class Tool:', '    def run(self): pass')
Set-Content -LiteralPath (Join-Path $proj 'node_modules\x\skip.js') -Value @('function ShouldBeSkipped() {}')
function MapRun([string]$ArgText, [bool]$Clm) {
    if ($Clm) {
        $c = '$ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"; & "' + $MapScript + '" ' + $ArgText + ' -Path "' + $proj + '"'
        return (powershell -NoProfile -NonInteractive -Command $c 2>&1 | Out-String)
    }
    return (powershell -NoProfile -NonInteractive -Command ('& "' + $MapScript + '" ' + $ArgText + ' -Path "' + $proj + '"') 2>&1 | Out-String)
}
$o = MapRun '-Action Build' $false
Check 'map: build finds 5 files and skips node_modules' ($o -match '5 files \(5 scanned' -and (Test-Path -LiteralPath (Join-Path $proj '.roguekit\codemap.json')))
$o = MapRun '-Action Build' $false
Check 'map: second build is incremental' ($o -match '0 scanned, 5 unchanged')
Check 'map: find returns definition with line number' ((MapRun '-Action Find -Name OrderService' $false) -match 'OrderService\.cs:5\s+class OrderService')
Check 'map: uses lists references' ((MapRun '-Action Uses -Name OrderService' $false) -match 'Caller\.cs:2')
Check 'map: outline lists methods' ((MapRun '-Action Outline -File OrderService.cs' $false) -match 'method GetOrderAsync')
Check 'map: deps finds importer by namespace' ((MapRun '-Action Deps -File OrderService.cs' $false) -match 'src/Caller\.cs')
Check 'map: deps finds importer by relative module' ((MapRun '-Action Deps -File util.js' $false) -match 'web/app\.js')
Check 'map: hubs lists imported modules' ((MapRun '-Action Hubs' $false) -match 'MyApp\.Orders')
Check 'map: status reports current' ((MapRun '-Action Status' $false) -match 'Map is current')
Check 'map: ignored folder not indexed' ((MapRun '-Action Find -Name ShouldBeSkipped' $false) -match 'No symbol')
Check 'map (constrained language): find' ((MapRun '-Action Find -Name OrderService' $true) -match 'OrderService\.cs:5')
Check 'map (constrained language): hubs and deps' (((MapRun '-Action Hubs' $true) -match 'MyApp\.Orders') -and ((MapRun '-Action Deps -File util.js' $true) -match 'web/app\.js'))
Add-Content -LiteralPath (Join-Path $proj 'web\util.js') -Value 'export function extra() {}'
Check 'map: status notices a changed file' ((MapRun '-Action Status' $false) -match '1 file\(s\) changed')
Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue

# --------------------------------------------------------------------------------------------------
if ($Online) {
    Section 'lookup.ps1 against live public APIs (-Online)'
    $r = (powershell -NoProfile -NonInteractive -File $Lookup -Kind Package -Ecosystem npm -Name express 2>&1 | Out-String)
    Check 'npm lookup returns a version' ($r -match 'npm express latest: \d')
    $r = (powershell -NoProfile -NonInteractive -File $Lookup -Kind Vulns -Ecosystem npm -Name lodash -Version 4.17.0 2>&1 | Out-String)
    Check 'OSV lookup returns advisories for an old lodash' ($r -match 'known vulnerabilit')
    $r = (powershell -NoProfile -NonInteractive -File $Lookup -Kind Package -Ecosystem npm -Name no-such-package-zzzxyz-12345 2>&1 | Out-String)
    Check 'missing package reports not found' ($LASTEXITCODE -eq 1 -and $r -match 'not found')
}

Write-Host ''
Write-Host ("Result: {0} passed, {1} failed" -f $script:pass, $script:fail)
if ($script:fail -gt 0) { exit 1 }
