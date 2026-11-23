<#
.SYNOPSIS
  Look up current facts from free public APIs: package versions, known vulnerabilities, end-of-life dates, GitHub releases.
.DESCRIPTION
  Needs only Windows PowerShell 5.1 or newer. No keys, no installs, nothing written to disk.
  Only the names and versions you pass are sent (never code or file contents), over HTTPS, to these services:
  npm registry, PyPI, NuGet, Maven Central, crates.io, OSV.dev, endoflife.date, GitHub.
.EXAMPLE
  lookup.ps1 -Kind Package -Ecosystem npm -Name express
  lookup.ps1 -Kind Package -Ecosystem maven -Name org.springframework.boot:spring-boot
  lookup.ps1 -Kind Vulns -Ecosystem pypi -Name django -Version 3.2.0
  lookup.ps1 -Kind Eol -Product dotnet
  lookup.ps1 -Kind Github -Name dotnet/runtime
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Package', 'Vulns', 'Eol', 'Github')][string]$Kind,
    [ValidateSet('npm', 'pypi', 'nuget', 'maven', 'crates')][string]$Ecosystem,
    [string]$Name,
    [string]$Version,
    [string]$Product,
    [int]$TimeoutSec = 30
)
$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.ServicePointManager]::SecurityProtocol } catch { }
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
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
if (Test-Offline) { Write-Err 'ROGUEKIT_OFFLINE is set: public API lookups are disabled on this machine.'; exit 3 }
$H = @{ 'User-Agent' = 'roguekit-lookup (+https://github.com/RogueAssassin/roguekit)'; 'Accept' = 'application/json' }

function Get-Json([string]$url) { Invoke-RestMethod -Uri $url -Headers $H -TimeoutSec $TimeoutSec -UseBasicParsing }
function Require([string]$v, [string]$label) { if (!$v) { throw "Missing $label." } }
function Enc([string]$s) {
    try { return [Uri]::EscapeDataString($s) } catch { }
    # Constrained Language Mode fallback: percent-encode ASCII; refuse anything else
    $o = ''
    foreach ($ch in $s.ToCharArray()) {
        $n = [int]$ch
        if ($ch -match '[A-Za-z0-9._~-]') { $o += $ch } elseif ($n -lt 128) { $o += ('%{0:X2}' -f $n) } else { throw 'Non-ASCII names are not supported in restricted PowerShell mode.' }
    }
    return $o
}

try {
    switch ($Kind) {
        'Package' {
            Require $Ecosystem '-Ecosystem'; Require $Name '-Name'
            switch ($Ecosystem) {
                'npm' {
                    $n = $Name -replace '/', '%2F'
                    $r = Get-Json "https://registry.npmjs.org/$n/latest"
                    "npm $($r.name) latest: $($r.version)"
                    if ($r.license) { "license: $($r.license)" }
                    if ($r.engines) { "engines: $(($r.engines.PSObject.Properties | ForEach-Object { $_.Name + ' ' + $_.Value }) -join ', ')" }
                    if ($r.deprecated) { "DEPRECATED: $($r.deprecated)" }
                }
                'pypi' {
                    $r = Get-Json "https://pypi.org/pypi/$(Enc $Name)/json"
                    "pypi $($r.info.name) latest: $($r.info.version)"
                    "requires-python: $($r.info.requires_python)"
                    "license: $($r.info.license)"
                    $files = $r.releases.($r.info.version)
                    if ($files) { "uploaded: $($files[0].upload_time)" }
                    if ($files -and $files[0].yanked) { "YANKED: $($files[0].yanked_reason)" }
                }
                'nuget' {
                    $r = Get-Json "https://api.nuget.org/v3-flatcontainer/$($Name.ToLowerInvariant())/index.json"
                    $stable = @($r.versions | Where-Object { $_ -notmatch '-' })
                    "nuget $Name latest stable: $($stable[-1])"
                    "latest overall: $($r.versions[-1])"
                }
                'maven' {
                    if ($Name -notmatch '^[^:]+:[^:]+$') { throw "Maven -Name must be group:artifact" }
                    $g, $a = $Name.Split(':')
                    $q = Enc ('g:"' + $g + '" AND a:"' + $a + '"')
                    $r = Get-Json "https://search.maven.org/solrsearch/select?q=$q&rows=1&wt=json"
                    if ($r.response.numFound -lt 1) { throw "Not found on Maven Central." }
                    "maven $Name latest: $($r.response.docs[0].latestVersion)"
                }
                'crates' {
                    $r = Get-Json "https://crates.io/api/v1/crates/$(Enc $Name)"
                    "crates.io $($r.crate.name) latest stable: $($r.crate.max_stable_version) (newest: $($r.crate.newest_version))"
                    "downloads: $($r.crate.downloads)"
                }
            }
        }
        'Vulns' {
            Require $Ecosystem '-Ecosystem'; Require $Name '-Name'; Require $Version '-Version'
            $eco = @{ npm = 'npm'; pypi = 'PyPI'; nuget = 'NuGet'; maven = 'Maven'; crates = 'crates.io' }[$Ecosystem]
            $body = @{ version = $Version; package = @{ name = $Name; ecosystem = $eco } } | ConvertTo-Json -Compress
            $r = Invoke-RestMethod -Method Post -Uri 'https://api.osv.dev/v1/query' -Headers $H -Body $body `
                -ContentType 'application/json; charset=utf-8' -TimeoutSec $TimeoutSec -UseBasicParsing
            $v = @($r.vulns)
            if ($v.Count -eq 0 -or !$v[0]) { "OSV: no known vulnerabilities for $Ecosystem $Name $Version"; break }
            "OSV: $($v.Count) known vulnerabilit$(if ($v.Count -eq 1) { 'y' } else { 'ies' }) for $Ecosystem $Name $Version"
            foreach ($x in ($v | Select-Object -First 15)) {
                $al = if ($x.aliases) { ' [' + (($x.aliases | Select-Object -First 3) -join ', ') + ']' } else { '' }
                "- $($x.id)$al : $($x.summary)"
            }
            if ($v.Count -gt 15) { "... and $($v.Count - 15) more (see https://osv.dev)" }
        }
        'Eol' {
            Require $Product '-Product (for example dotnet, python, nodejs, java, php, ubuntu)'
            $r = Get-Json "https://endoflife.date/api/$(Enc $Product).json"
            "endoflife.date: $Product (newest cycles first)"
            foreach ($c in ($r | Select-Object -First 6)) {
                "- $($c.cycle): eol=$($c.eol) latest=$($c.latest) lts=$($c.lts)"
            }
        }
        'Github' {
            Require $Name '-Name (owner/repo)'
            if ($Name -notmatch '^[\w.-]+/[\w.-]+$') { throw 'Use -Name owner/repo' }
            try {
                $r = Get-Json "https://api.github.com/repos/$Name/releases/latest"
                "$Name latest release: $($r.tag_name) ($($r.published_at))"
                if ($r.name) { "name: $($r.name)" }
                "url: $($r.html_url)"
            } catch {
                $t = @(Get-Json "https://api.github.com/repos/$Name/tags?per_page=1")
                if ($t.Count -gt 0 -and $t[0]) { "$Name has no releases; newest tag: $($t[0].name)" } else { throw }
            }
            "(unauthenticated GitHub API allows about 60 requests per hour)"
        }
    }
}
catch {
    $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch { }
    $msg = if ($code -eq 404) { 'not found' } elseif ($code -eq 403 -or $code -eq 429) { "rate limited or blocked (HTTP $code); try later" } else { $_.Exception.Message }
    Write-Err ("lookup failed: $msg")
    exit 1
}
