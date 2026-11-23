<#
.SYNOPSIS
  Ask a free (or local) OpenAI-compatible model API for help. Needs only Windows PowerShell 5.1 or newer.
.DESCRIPTION
  Nothing to install and nothing changed on your machine by default. Keys are saved only if you run
  -Action SaveKey yourself, encrypted for your Windows user (DPAPI) under ~/.roguekit/keys. Environment
  variables (for example GROQ_API_KEY) also work and are only read, never written.
  Prompts are sent ONLY to the provider(s) you name, over HTTPS (plain HTTP only to loopback for local models).
.EXAMPLE
  ask-free.ps1 -Action ListModels -Provider groq
  ask-free.ps1 -Action SaveKey -Provider groq
  ask-free.ps1 -Target groq/<model-id>,openrouter/<model-id>:free -Prompt "Summarise: ..."
  Get-Content notes.txt | ask-free.ps1 -Target groq/<model-id> -System "Be brief."
#>
param(
    [ValidateSet('Ask', 'SaveKey', 'ListModels', 'Status', 'SaveDefault')][string]$Action = 'Ask',
    [string]$Provider,
    [string[]]$Target,
    [string]$Prompt,
    [string]$PromptFile,
    [string]$System,
    [string]$BaseUrl,
    [string]$Filter,
    [int]$MaxTokens = 1024,
    [double]$Temperature = 0.2,
    [int]$TimeoutSec = 120,
    [int]$MaxChars = 60000,
    [int]$Retries = 2,
    [switch]$DryRun,
    [switch]$AllowSecrets
)
$ErrorActionPreference = 'Stop'
function Write-Err([string]$m) {
    # stderr line; falls back to Write-Error where .NET calls are restricted (Constrained Language Mode)
    try { [Console]::Error.WriteLine($m) } catch { Write-Error -Message $m -ErrorAction Continue }
}
function Get-Env([string]$n) {
    $i = Get-Item -LiteralPath ('env:' + $n) -ErrorAction SilentlyContinue
    if ($i) { return $i.Value }
    return $null
}
function Test-Offline { return ((Get-Env 'ROGUEKIT_OFFLINE') -in '1', 'true', 'on', 'yes') }
trap { Write-Err $_.Exception.Message; exit 1 }
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.ServicePointManager]::SecurityProtocol } catch { }
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

if ($Target) { $Target = @($Target | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

# Base URLs and key variable names only. No model IDs or quotas: both change often. Use -Action ListModels.
$Presets = @{
    'groq'       = @{ Url = 'https://api.groq.com/openai/v1';                               Env = 'GROQ_API_KEY' }
    'openrouter' = @{ Url = 'https://openrouter.ai/api/v1';                                 Env = 'OPENROUTER_API_KEY' }
    'gemini'     = @{ Url = 'https://generativelanguage.googleapis.com/v1beta/openai';      Env = 'GEMINI_API_KEY' }
    'nvidia'     = @{ Url = 'https://integrate.api.nvidia.com/v1';                          Env = 'NVIDIA_API_KEY' }
    'mistral'    = @{ Url = 'https://api.mistral.ai/v1';                                     Env = 'MISTRAL_API_KEY' }
    'github'     = @{ Url = 'https://models.github.ai/inference';                           Env = 'GITHUB_MODELS_TOKEN' }
    'cerebras'   = @{ Url = 'https://api.cerebras.ai/v1';                                   Env = 'CEREBRAS_API_KEY' }
    'ollama'     = @{ Url = 'http://127.0.0.1:11434/v1';                                    Env = '' }
    'lmstudio'   = @{ Url = 'http://127.0.0.1:1234/v1';                                     Env = '' }
    'custom'     = @{ Url = '';                                                             Env = 'CUSTOM_API_KEY' }
}
$StateDir = Join-Path $HOME '.roguekit'
$homeOverride = Get-Env 'ROGUEKIT_HOME'
if ($homeOverride) { $StateDir = $homeOverride }
$KeyDir = Join-Path $StateDir 'keys'
$DefaultFile = Join-Path $StateDir 'free-models.json'

function Get-Base([string]$name) {
    if (!$Presets.ContainsKey($name)) { throw "Unknown provider '$name'. Known: $(($Presets.Keys | Sort-Object) -join ', ')." }
    $u = $Presets[$name].Url
    if ($name -eq 'custom') { $u = $BaseUrl }
    if (!$u) { throw "Provider '$name' needs -BaseUrl." }
    if ((Test-Offline) -and $u -notmatch '^http://(127\.0\.0\.1|localhost|\[::1\])') { throw 'ROGUEKIT_OFFLINE is set: only local model servers (localhost) are allowed.' }
    $isLoop = $u -match '^http://(127\.0\.0\.1|localhost|\[::1\])(:\d+)?(/|$)'
    if ($u -notmatch '^https://' -and !$isLoop) { throw "Refusing non-HTTPS URL for a remote host: $u" }
    return $u.TrimEnd('/')
}

function Get-Key([string]$name) {
    $f = Join-Path $KeyDir ($name + '.key')
    if (Test-Path -LiteralPath $f) {
        try {
            $sec = ConvertTo-SecureString (Get-Content -LiteralPath $f -Raw).Trim()
            $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
            try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
        }
        catch { Write-Err "Saved key for $name could not be read here (restricted PowerShell mode, or saved by a different Windows user). Use the provider's environment variable instead." }
    }
    $envName = $Presets[$name].Env
    if ($envName) { $v = Get-Env $envName; if ($v) { return $v } }
    return $null
}

function Test-IsLocal([string]$u) { return $u -match '^http://' }

function Invoke-Api([string]$method, [string]$url, [string]$key, [string]$json) {
    $h = @{ 'Accept' = 'application/json' }
    if ($key) { $h['Authorization'] = 'Bearer ' + $key }
    $args2 = @{ Method = $method; Uri = $url; Headers = $h; TimeoutSec = $TimeoutSec; UseBasicParsing = $true }
    if ($json) {
        try { $args2['Body'] = [Text.Encoding]::UTF8.GetBytes($json) } catch { $args2['Body'] = $json }
        $args2['ContentType'] = 'application/json; charset=utf-8'
    }
    Invoke-RestMethod @args2
}

function Get-HttpStatus($err) {
    try { return [int]$err.Exception.Response.StatusCode } catch { return 0 }
}

function Get-RetryAfter($err) {
    try { $v = $err.Exception.Response.Headers['Retry-After']; if ($v -match '^\d+$') { return [Math]::Min([int]$v, 10) } } catch { }
    return 0
}

function Test-SecretLike([string]$text) {
    $rules = @(
        @('private key', '-----BEGIN [A-Z ]*PRIVATE KEY-----'),
        @('AWS access key', 'AKIA[0-9A-Z]{16}'),
        @('GitHub token', 'gh[pousr]_[A-Za-z0-9]{30,}'),
        @('API key (sk-)', 'sk-[A-Za-z0-9_-]{20,}'),
        @('Google API key', 'AIza[0-9A-Za-z_-]{30,}'),
        @('Slack token', 'xox[baprs]-[A-Za-z0-9-]{10,}'),
        @('assigned secret', '(?i)(password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*["'']?[^\s"'']{8,}')
    )
    foreach ($r in $rules) { if ($text -match $r[1]) { return $r[0] } }
    return $null
}

switch ($Action) {
    'Status' {
        Write-Host 'Providers (key source only, values are never shown):'
        foreach ($n in ($Presets.Keys | Sort-Object)) {
            $src = 'none'
            if (Test-Path -LiteralPath (Join-Path $KeyDir ($n + '.key'))) { $src = 'saved key (encrypted)' }
            elseif ($Presets[$n].Env -and (Get-Env ($Presets[$n].Env))) { $src = 'environment variable ' + $Presets[$n].Env }
            elseif (!$Presets[$n].Env -or $n -in 'ollama', 'lmstudio') { $src = 'no key needed (local)' }
            Write-Host ('  {0,-11} {1}' -f $n, $src)
        }
        if (Test-Path -LiteralPath $DefaultFile) { Write-Host ('Default targets: ' + ((Get-Content -LiteralPath $DefaultFile -Raw | ConvertFrom-Json).targets -join ', ')) }
        else { Write-Host 'Default targets: none (use -Target provider/model)' }
        return
    }
    'SaveKey' {
        if (!$Provider) { throw 'Use -Provider <name>.' }
        [void](Get-Base $Provider)
        $sec = Read-Host -AsSecureString ("Paste your $Provider API key (input hidden)")
        if ($sec.Length -eq 0) { throw 'No key entered.' }
        if (!(Test-Path -LiteralPath $KeyDir)) { New-Item -ItemType Directory -Path $KeyDir -Force | Out-Null }
        ConvertFrom-SecureString $sec | Set-Content -LiteralPath (Join-Path $KeyDir ($Provider + '.key')) -Encoding ASCII
        Write-Host "Saved encrypted key for $Provider (only your Windows user can decrypt it). Delete ~/.roguekit/keys/$Provider.key to remove."
        return
    }
    'SaveDefault' {
        if (!$Target) { throw 'Use -Target provider/model[,provider/model...].' }
        if (!(Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
        (@{ targets = @($Target) } | ConvertTo-Json) | Set-Content -LiteralPath $DefaultFile -Encoding UTF8
        Write-Host "Saved default targets: $($Target -join ', ')"
        return
    }
    'ListModels' {
        if (!$Provider) { throw 'Use -Provider <name>.' }
        $base = Get-Base $Provider
        $key = Get-Key $Provider
        if (!$key -and !(Test-IsLocal $base)) { throw "No key for $Provider. Run -Action SaveKey -Provider $Provider, or set $($Presets[$Provider].Env)." }
        $r = Invoke-Api 'GET' ($base + '/models') $key $null
        $items = if ($r.data) { $r.data } else { $r }
        $ids = @($items | ForEach-Object { if ($_.id) { $_.id } elseif ($_.name) { $_.name } }) | Sort-Object
        if ($Filter) { $ids = $ids | Where-Object { $_ -like "*$Filter*" } }
        $ids | ForEach-Object { "$Provider/$_" }
        return
    }
}

# ---- Ask ----
if (!$Target) {
    if (Test-Path -LiteralPath $DefaultFile) { $Target = @((Get-Content -LiteralPath $DefaultFile -Raw | ConvertFrom-Json).targets) }
    if (!$Target) { throw 'No -Target given and no default saved. Example: -Target groq/<model-id> (list models with -Action ListModels).' }
}
$text = $Prompt
if ($PromptFile) { $text = Get-Content -LiteralPath $PromptFile -Raw -Encoding UTF8 }
if (!$text -and $MyInvocation.ExpectingInput) { $text = ($input | Out-String) }
if (!$text) { throw 'Give -Prompt, -PromptFile or pipe text in.' }
if ($text.Length -gt $MaxChars) { throw "Prompt is $($text.Length) characters (limit $MaxChars). Send less, or raise -MaxChars knowingly." }
if (!$AllowSecrets) {
    $hit = Test-SecretLike (($System + "`n" + $text))
    if ($hit) { throw "Refusing to send: the text looks like it contains a secret ($hit). Remove it, or use -AllowSecrets only if you are sure." }
}

$msgs = @()
if ($System) { $msgs += @{ role = 'system'; content = $System } }
$msgs += @{ role = 'user'; content = $text }

$lastErr = 'no target tried'
foreach ($t in $Target) {
    $i = $t.IndexOf('/')
    if ($i -lt 1 -or $i -ge $t.Length - 1) { $lastErr = "Target '$t' must look like provider/model"; continue }
    $pname = $t.Substring(0, $i)
    $model = $t.Substring($i + 1)
    try { $base = Get-Base $pname } catch { $lastErr = $_.Exception.Message; continue }
    $key = Get-Key $pname
    if (!$key -and !(Test-IsLocal $base)) { $lastErr = "No key for $pname (run -Action SaveKey -Provider $pname)"; continue }

    $body = @{ model = $model; messages = $msgs; max_tokens = $MaxTokens; temperature = $Temperature } | ConvertTo-Json -Depth 6 -Compress
    if ($DryRun) {
        Write-Err (("[dry run] would send {0} characters to {1} (model {2}); nothing was sent." -f $text.Length, $pname, $model))
        return
    }
    for ($a = 0; $a -le $Retries; $a++) {
        $t0 = Get-Date
        try {
            $r = Invoke-Api 'POST' ($base + '/chat/completions') $key $body
            $content = $null
            if ($r.choices -and $r.choices.Count -gt 0) { $content = $r.choices[0].message.content }
            if (!$content) { throw 'empty reply' }
            Write-Err (("[free-model] {0}/{1} ok in {2:N1}s" -f $pname, $model, ((Get-Date) - $t0).TotalSeconds))
            Write-Output $content
            return
        }
        catch {
            $code = Get-HttpStatus $_
            $lastErr = "$pname/$model failed" + $(if ($code) { " (HTTP $code)" } else { ': ' + $_.Exception.Message })
            Write-Err ("[free-model] $lastErr")
            if (($code -in 429, 500, 502, 503, 504) -and $a -lt $Retries) {
                $wait = Get-RetryAfter $_
                if (!$wait) { $wait = 2 * ($a + 1) }
                Start-Sleep -Seconds $wait
                continue
            }
            break
        }
    }
}
Write-Err ("All targets failed. Last problem: $lastErr")
exit 1
