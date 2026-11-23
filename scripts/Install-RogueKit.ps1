<#
.SYNOPSIS
    RogueKit installer: installs the RogueKit plugin and global rules for Claude Code, and manages optional extras.

.DESCRIPTION
    Actions:
      Install    Install/refresh the plugin (skills, agents, token-saver hook) and the managed block in the global CLAUDE.md.
                 Also removes an older "ClaudePack" install if one is found (only files that are still unmodified).
      Status     Show what is installed.
      Doctor     Run health checks (CLI, plugin, hook, rules block, duplicates) and print PASS/WARN/FAIL.
      Audit      Estimate always-on context cost of instructions, skills, agents, plugins and MCP servers.
      Uninstall  Remove the plugin, its marketplace entry and the managed rules block.

    Everything supports -WhatIf. The installer never edits settings.json, credentials or project files.

.EXAMPLE
    .\Install-RogueKit.ps1 -WhatIf
    .\Install-RogueKit.ps1
    .\Install-RogueKit.ps1 -Action Doctor
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Install', 'Status', 'Doctor', 'Audit', 'Uninstall')]
    [string]$Action = 'Install',
    # Marketplace source: a local folder (default: this repo) or "owner/repo" / a git URL.
    [string]$Source,
    [switch]$SkipPlugin,
    [switch]$SkipRules,
    # Do not remove an older ClaudePack install.
    [switch]$KeepOldPack,
    # Opt-in MCP servers (user scope). They run third-party npm packages and need Node.js.
    [ValidateSet('context7', 'playwright', 'chrome-devtools')]
    [string[]]$McpServers = @()
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$KitName = 'RogueKit'
$PluginName = 'roguekit'
$MarketplaceName = 'roguekit'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$HomeDir = $env:USERPROFILE
$ClaudeDir = if ([string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) { Join-Path $HomeDir '.claude' } else { $env:CLAUDE_CONFIG_DIR }
$DataDir = Join-Path $HomeDir '.roguekit'
$BeginMark = '<!-- BEGIN ROGUEKIT MANAGED -->'
$EndMark = '<!-- END ROGUEKIT MANAGED -->'
$OldBegin = '<!-- BEGIN CLAUDEPACK MANAGED INSTRUCTIONS -->'
$OldEnd = '<!-- END CLAUDEPACK MANAGED INSTRUCTIONS -->'
$OldPackDir = Join-Path $HomeDir 'ClaudeCode-Global-Pack'
$KitVersion = try { (Get-Content -LiteralPath (Join-Path $RepoRoot 'plugin\.claude-plugin\plugin.json') -Raw | ConvertFrom-Json).version } catch { 'unknown' }

function Get-FileHashOrNull([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
    return $null
}
function Write-Utf8File([string]$Path, [string]$Content) {
    $parent = Split-Path -Parent $Path
    if (!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}
function Test-Claude { return [bool](Get-Command 'claude' -ErrorAction SilentlyContinue) }

# ---------------------------------------------------------------------------
# Optional extras (MCP servers) and CLI helper
# ---------------------------------------------------------------------------
$McpCatalog = @{
    'context7'        = @('@upstash/context7-mcp')                 # up-to-date library docs
    'playwright'      = @('@playwright/mcp@latest')                # browser automation / UI testing
    'chrome-devtools' = @('chrome-devtools-mcp@latest')            # live UI inspection / performance
}

function Invoke-ClaudeCli([string[]]$CliArgs) {
    # Run the claude CLI without letting native stderr trip $ErrorActionPreference = 'Stop'.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & claude @CliArgs 2>&1 | ForEach-Object { "$_" }
        return [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = ($out -join "`n") }
    }
    finally { $ErrorActionPreference = $prev }
}

function Install-McpServers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string[]]$Names)
    if ($Names.Count -eq 0) { return }
    if (!(Get-Command 'claude' -ErrorAction SilentlyContinue)) { Write-Warning 'Claude CLI not found on PATH; MCP servers not added.'; return }
    $existing = (Invoke-ClaudeCli @('mcp', 'list')).Output
    foreach ($name in $Names) {
        if ($existing -match "(?m)^\s*$([regex]::Escape($name))\b") { Write-Host "MCP server already configured, preserved: $name"; continue }
        $pkg = $McpCatalog[$name][0]
        if ($PSCmdlet.ShouldProcess($name, "Add user-scope MCP server running third-party npm package '$pkg'")) {
            $r = Invoke-ClaudeCli @('mcp', 'add', '--scope', 'user', $name, '--', 'cmd', '/c', 'npx', '-y', $pkg)
            if ($r.ExitCode -eq 0) { Write-Host "Added MCP server: $name ($pkg). Restart Claude Code to load it." }
            else { Write-Warning "Failed to add MCP server '$name': $($r.Output)" }
        }
    }
}

# ---------------------------------------------------------------------------
# Global rules block (the one thing a plugin cannot ship)
# ---------------------------------------------------------------------------
function Get-BlockPattern([string]$Begin, [string]$End) { return '(?s)' + [regex]::Escape($Begin) + '.*?' + [regex]::Escape($End) }

function Get-RulesText {
    $p = Join-Path $RepoRoot 'rules\global-rules.md'
    if (!(Test-Path -LiteralPath $p)) { throw "Rules file not found: $p" }
    return (Get-Content -LiteralPath $p -Raw).Replace("`r`n", "`n").Trim()
}

function Backup-ClaudeMd([string]$Path) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $dest = Join-Path (Join-Path $DataDir 'backups') "CLAUDE.md.$stamp"
    New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
    Copy-Item -LiteralPath $Path -Destination $dest -Force
    Write-Host "Backed up CLAUDE.md -> $dest"
}

function Set-RulesBlock {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $target = Join-Path $ClaudeDir 'CLAUDE.md'
    $raw = if (Test-Path -LiteralPath $target -PathType Leaf) { Get-Content -LiteralPath $target -Raw } else { '' }
    $useLf = ($raw -match "`n") -and ($raw -notmatch "`r`n")
    $norm = $raw.Replace("`r`n", "`n")
    $block = "$BeginMark`n$(Get-RulesText)`n$EndMark"

    $newPat = Get-BlockPattern $BeginMark $EndMark
    $oldPat = Get-BlockPattern $OldBegin $OldEnd
    $ev = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $block }
    if ([regex]::IsMatch($norm, $newPat)) { $result = [regex]::Replace($norm, $newPat, $ev) }
    elseif ([regex]::IsMatch($norm, $oldPat)) { $result = [regex]::Replace($norm, $oldPat, $ev) }
    elseif ([string]::IsNullOrWhiteSpace($norm)) { $result = $block }
    else { $result = $norm.TrimEnd() + "`n`n" + $block }
    $result = $result.TrimEnd() + "`n"

    if ($result -ceq $norm) { Write-Host 'Unchanged: global CLAUDE.md rules block'; return }
    if ($PSCmdlet.ShouldProcess($target, 'Write RogueKit managed rules block (backup first; your other content is kept)')) {
        Backup-ClaudeMd $target
        $out = if ($useLf) { $result } else { $result.Replace("`n", "`r`n") }
        Write-Utf8File -Path $target -Content $out
        Write-Host "Updated: $target (managed block only)"
    }
}

function Remove-RulesBlock {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $target = Join-Path $ClaudeDir 'CLAUDE.md'
    if (!(Test-Path -LiteralPath $target -PathType Leaf)) { return }
    $raw = Get-Content -LiteralPath $target -Raw
    $useLf = ($raw -match "`n") -and ($raw -notmatch "`r`n")
    $norm = $raw.Replace("`r`n", "`n")
    $res = [regex]::Replace($norm, (Get-BlockPattern $BeginMark $EndMark), '')
    if ($res -ceq $norm) { Write-Host 'No RogueKit rules block found in CLAUDE.md.'; return }
    $res = ([regex]::Replace($res, "\n{3,}", "`n`n")).Trim()
    if ($PSCmdlet.ShouldProcess($target, 'Remove RogueKit managed rules block only')) {
        Backup-ClaudeMd $target
        $out = if ($res) { $res + "`n" } else { '' }
        if (-not $useLf) { $out = $out.Replace("`n", "`r`n") }
        Write-Utf8File -Path $target -Content $out
        Write-Host 'Removed RogueKit rules block from CLAUDE.md (your other content kept).'
    }
}

# ---------------------------------------------------------------------------
# Older "ClaudePack" install: remove only what is provably unmodified
# ---------------------------------------------------------------------------
function Invoke-OldPackMigration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $payload = Join-Path $OldPackDir 'payload'
    $oldPlugin = $false
    if (Test-Claude) { $oldPlugin = ((Invoke-ClaudeCli @('plugin', 'list')).Output -match 'claudepack-token-saver@claudepack') }
    if (!(Test-Path -LiteralPath $payload) -and !$oldPlugin) { return }
    Write-Host 'Found an older ClaudePack install. Removing its unmodified files so skills and hooks are not duplicated.'

    if ($oldPlugin -and $PSCmdlet.ShouldProcess('claudepack-token-saver@claudepack', 'Uninstall old plugin and marketplace')) {
        [void](Invoke-ClaudeCli @('plugin', 'uninstall', 'claudepack-token-saver@claudepack'))
        [void](Invoke-ClaudeCli @('plugin', 'marketplace', 'remove', 'claudepack'))
        Write-Host 'Removed old plugin: claudepack-token-saver'
    }
    if (Test-Path -LiteralPath $payload) {
        foreach ($f in Get-ChildItem -LiteralPath $payload -Recurse -File) {
            $rel = $f.FullName.Substring($payload.Length + 1)
            if ($rel -eq 'CLAUDE.md') { continue }
            $t = Join-Path $ClaudeDir $rel
            if (!(Test-Path -LiteralPath $t -PathType Leaf)) { continue }
            if ((Get-FileHashOrNull $t) -eq (Get-FileHashOrNull $f.FullName)) {
                if ($PSCmdlet.ShouldProcess($t, 'Remove unmodified old ClaudePack file')) {
                    Remove-Item -LiteralPath $t -Force
                    Write-Host "Removed old file: $rel"
                    $dir = Split-Path -Parent $t
                    if (!(Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue)) { Remove-Item -LiteralPath $dir -Force }
                }
            }
            else { Write-Warning "Kept modified old file: $rel (it may duplicate a RogueKit skill; review or delete it yourself)" }
        }
    }
    Write-Host "Old ClaudePack data folder left in place (safe to delete when you are happy): $OldPackDir"
}

# ---------------------------------------------------------------------------
# Plugin
# ---------------------------------------------------------------------------
function Install-KitPlugin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $src = if ($Source) { $Source } else { $RepoRoot }
    $manual = "Install inside Claude Code instead:`n  /plugin marketplace add $src`n  /plugin install $PluginName@$MarketplaceName"
    if (!(Test-Claude)) { Write-Warning "Claude CLI not found on PATH; plugin not installed.`n$manual"; return }
    if (!$Source -and !(Test-Path -LiteralPath (Join-Path $RepoRoot '.claude-plugin\marketplace.json'))) {
        throw "marketplace.json not found under '$RepoRoot'. Run this script from a full RogueKit checkout or pass -Source."
    }
    if (!$PSCmdlet.ShouldProcess($src, "Add marketplace '$MarketplaceName' and install plugin '$PluginName' (local hook script, no network)")) { return }

    $ml = (Invoke-ClaudeCli @('plugin', 'marketplace', 'list')).Output
    if ($ml -match "(?m)\b$MarketplaceName\b") { [void](Invoke-ClaudeCli @('plugin', 'marketplace', 'update', $MarketplaceName)) }
    else {
        $add = Invoke-ClaudeCli @('plugin', 'marketplace', 'add', $src)
        if ($add.ExitCode -ne 0) { Write-Warning "Marketplace add failed: $($add.Output)`n$manual"; return }
    }
    $pl = (Invoke-ClaudeCli @('plugin', 'list')).Output
    if ($pl -match "$PluginName@$MarketplaceName") {
        [void](Invoke-ClaudeCli @('plugin', 'update', "$PluginName@$MarketplaceName"))
        Write-Host "Plugin already installed: $PluginName (marketplace refreshed; restart Claude to apply updates)"
        return
    }
    $inst = Invoke-ClaudeCli @('plugin', 'install', "$PluginName@$MarketplaceName")
    if ($inst.ExitCode -ne 0) { Write-Warning "Plugin install failed: $($inst.Output)`n$manual"; return }
    Write-Host "Installed plugin: $PluginName@$MarketplaceName"
    if (!$Source) { Write-Host "Note: the marketplace points at '$RepoRoot'. Keep this folder, or reinstall from GitHub with -Source owner/repo." }
}

function Get-PluginBlock {
    # Returns the 'claude plugin list' text block for this plugin, or $null.
    if (!(Test-Claude)) { return $null }
    $pl = (Invoke-ClaudeCli @('plugin', 'list')).Output
    # Entries start with a short pointer ('>' or a glyph that Windows PowerShell may garble into
    # 1-3 characters) followed by 'name@marketplace'. Match on the name line, not the glyph.
    $m = [regex]::Match($pl, '(?m)^\s*\S{1,3}\s+' + [regex]::Escape("$PluginName@$MarketplaceName") + '\s*\r?$')
    if (!$m.Success) { return $null }
    $rest = $pl.Substring($m.Index)
    $next = [regex]::Match($rest.Substring($m.Length), '(?m)^\s*\S{1,3}\s+[\w.-]+@[\w.-]+\s*\r?$')
    if ($next.Success) { return $rest.Substring(0, $m.Length + $next.Index) }
    return $rest
}

# ---------------------------------------------------------------------------
# Status / Doctor / Audit
# ---------------------------------------------------------------------------
function Show-Status {
    Write-Host "$KitName $KitVersion (repo: $RepoRoot)"
    Write-Host "Claude config: $ClaudeDir"
    Write-Host ("Claude CLI:    " + $(if (Test-Claude) { (Get-Command 'claude').Source } else { 'not on PATH' }))
    $b = Get-PluginBlock
    Write-Host ("Plugin:        " + $(if ($b) { 'installed' + $(if ($b -match 'enabled') { ' (enabled)' } else { ' (NOT enabled)' }) } else { 'not installed' }))
    $f = Join-Path $ClaudeDir 'CLAUDE.md'
    $has = (Test-Path -LiteralPath $f) -and ((Get-Content -LiteralPath $f -Raw).Contains($BeginMark))
    Write-Host "Rules block:   $has"
    Write-Host ("Old ClaudePack: " + $(if (Test-Path -LiteralPath (Join-Path $OldPackDir 'payload')) { 'found (run Install to migrate)' } else { 'none' }))
}

function Invoke-Doctor {
    $script:fail = 0
    function Out-Check([string]$Level, [string]$Msg) {
        if ($Level -eq 'FAIL') { $script:fail++ }
        Write-Host ("[{0}] {1}" -f $Level, $Msg)
    }
    Write-Host "$KitName $KitVersion doctor"
    $PSVersionTable.PSVersion | ForEach-Object { Out-Check 'PASS' "PowerShell $_ available" }

    if (Test-Claude) { Out-Check 'PASS' ("Claude CLI: " + ((Invoke-ClaudeCli @('--version')).Output.Trim())) }
    else { Out-Check 'FAIL' 'Claude CLI not on PATH' }

    $b = Get-PluginBlock
    if (!$b) { Out-Check 'FAIL' "Plugin $PluginName@$MarketplaceName is not installed (run Install)" }
    else {
        if ($b -match 'enabled') { Out-Check 'PASS' 'Plugin installed and enabled' } else { Out-Check 'FAIL' 'Plugin installed but not enabled (claude plugin enable roguekit)' }
        $guard = $null
        if ($b -match 'Read from:\s*(.+)') { $guard = Join-Path $Matches[1].Trim() 'hooks\token-guard.ps1' }
        if ($guard -and (Test-Path -LiteralPath $guard)) {
            $sample = '{"tool_name":"Bash","tool_input":{"command":"git log"}}'
            $prevOff = $env:ROGUEKIT_TOKEN_SAVER; $env:ROGUEKIT_TOKEN_SAVER = $null
            # Run it exactly as Claude Code does (no execution-policy override), so this reflects reality on managed machines.
            try { $o = ($sample | powershell -NoProfile -NonInteractive -File $guard 2>&1 | Out-String) } finally { $env:ROGUEKIT_TOKEN_SAVER = $prevOff }
            if ($o -match '"deny"') { Out-Check 'PASS' 'Token-saver hook denies an unbounded "git log" as expected' }
            elseif ($o -match 'running scripts is disabled|not digitally signed|PSSecurityException|UnauthorizedAccess') {
                Out-Check 'WARN' 'PowerShell execution policy blocks the hook script, so the token saver is inactive (Claude still works). Ask your administrator to allow or sign it; see docs/managed-devices.md. Do not bypass policy on a managed device.'
            }
            else { Out-Check 'FAIL' 'Token-saver hook did not deny an unbounded "git log"' }
        }
        else { Out-Check 'WARN' 'Could not locate the plugin hook script to test it' }
    }

    $f = Join-Path $ClaudeDir 'CLAUDE.md'
    $txt = if (Test-Path -LiteralPath $f) { Get-Content -LiteralPath $f -Raw } else { '' }
    $n = ([regex]::Matches($txt, [regex]::Escape($BeginMark))).Count
    if ($n -eq 1) { Out-Check 'PASS' 'Global CLAUDE.md has exactly one RogueKit rules block' }
    elseif ($n -eq 0) { Out-Check 'WARN' 'No RogueKit rules block in global CLAUDE.md (run Install without -SkipRules)' }
    else { Out-Check 'FAIL' "RogueKit rules block appears $n times in CLAUDE.md" }
    if ($txt.Contains($OldBegin)) { Out-Check 'WARN' 'Old ClaudePack rules block still present (run Install to replace it)' }

    $oldPl = (Test-Claude) -and ((Invoke-ClaudeCli @('plugin', 'list')).Output -match 'claudepack-token-saver@claudepack')
    if ($oldPl) { Out-Check 'WARN' 'Old claudepack-token-saver plugin is still installed (duplicate hook); run Install to remove it' }

    $dups = @()
    $pluginSkills = Join-Path $RepoRoot 'plugin\skills'
    if (Test-Path -LiteralPath $pluginSkills) {
        foreach ($d in Get-ChildItem -LiteralPath $pluginSkills -Directory) {
            if (Test-Path -LiteralPath (Join-Path $ClaudeDir "skills\$($d.Name)\SKILL.md")) { $dups += $d.Name }
        }
    }
    if ($dups.Count) { Out-Check 'WARN' ("User-level skills duplicate plugin skills: " + ($dups -join ', ') + ' (remove the user-level copies to avoid duplicate context)') }
    else { Out-Check 'PASS' 'No duplicate user-level skills' }

    # The bundled helper scripts must exist and parse (catches a broken or partial download).
    foreach ($rel in 'plugin\skills\free-model-assist\scripts\ask-free.ps1', 'plugin\skills\free-apis\scripts\lookup.ps1', 'plugin\skills\code-map\scripts\map.ps1', 'plugin\hooks\token-guard.ps1') {
        $sp = Join-Path $RepoRoot $rel
        if (!(Test-Path -LiteralPath $sp)) { Out-Check 'FAIL' "Missing helper script: $rel"; continue }
        $perr = $null; $ptok = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($sp, [ref]$ptok, [ref]$perr)
        if ($perr -and $perr.Count -gt 0) { Out-Check 'FAIL' "Helper script has syntax errors: $rel" } else { Out-Check 'PASS' "Helper script parses: $(Split-Path -Leaf $sp)" }
    }

    if ($env:ROGUEKIT_TOKEN_SAVER -eq 'off' -or $env:CLAUDEPACK_TOKEN_SAVER -eq 'off') { Out-Check 'WARN' 'Token saver is switched off by environment variable' }
    Write-Host ("Result: {0} failure(s)" -f $script:fail)
    if ($script:fail -gt 0) { exit 1 }
}

function Invoke-Audit {
    Write-Host "$KitName audit: always-on context estimates (about 4 characters per token; real counts differ)"
    $gf = Join-Path $ClaudeDir 'CLAUDE.md'
    if (Test-Path -LiteralPath $gf) {
        $len = (Get-Item -LiteralPath $gf).Length
        Write-Host ("Global CLAUDE.md : {0:n0} bytes, ~{1:n0} tok every session" -f $len, ($len / 4))
    }
    $skillRoot = Join-Path $ClaudeDir 'skills'
    if (Test-Path -LiteralPath $skillRoot) {
        $rows = @(foreach ($d in Get-ChildItem -LiteralPath $skillRoot -Directory -ErrorAction SilentlyContinue) {
                $md = Join-Path $d.FullName 'SKILL.md'
                if (!(Test-Path -LiteralPath $md)) { continue }
                $text = Get-Content -LiteralPath $md -Raw
                $desc = if ($text -match '(?m)^description:\s*(.+)$') { $Matches[1] } else { '' }
                [PSCustomObject]@{ Skill = $d.Name; DescTok = [int](($d.Name.Length + $desc.Length) / 4); FullTok = [int]((Get-Item -LiteralPath $md).Length / 4) }
            })
        Write-Host ("User-level skills: {0}, ~{1} tok of descriptions every session" -f $rows.Count, (($rows | Measure-Object DescTok -Sum).Sum))
        $rows | Sort-Object DescTok -Descending | Select-Object -First 5 | ForEach-Object { Write-Host ("    {0,-24} desc ~{1} tok, full ~{2} tok (full text loads only when invoked)" -f $_.Skill, $_.DescTok, $_.FullTok) }
    }
    if (Test-Claude) {
        $pl = (Invoke-ClaudeCli @('plugin', 'list')).Output
        # Entries start with a short pointer ('>' or a glyph that Windows PowerShell may garble); match the name@marketplace line.
        $names = @([regex]::Matches($pl, '(?m)^\s*\S{1,3}\s+([^\s@]+)@(\S+)\s*\r?$') | ForEach-Object { $_.Groups[1].Value })
        Write-Host "Plugins: $($names.Count) installed"
        $blk = Get-PluginBlock
        if ($blk -and $blk -match 'Read from:\s*(.+)') {
            $root = $Matches[1].Trim()
            $cost = {
                param($dir, $leaf)
                $count = 0; $chars = 0
                if (Test-Path -LiteralPath $dir) {
                    foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -Filter $leaf -File -ErrorAction SilentlyContinue)) {
                        $t = Get-Content -LiteralPath $f.FullName -Raw
                        if ($t -match '(?m)^name:\s*(.+)$') { $nm = $Matches[1].Trim() } else { $nm = '' }
                        if ($t -match '(?m)^description:\s*(.+)$') { $ds = $Matches[1].Trim() } else { $ds = '' }
                        $count++; $chars += $nm.Length + $ds.Length
                    }
                }
                [PSCustomObject]@{ Count = $count; Tok = [int]($chars / 4) }
            }
            $sk = & $cost (Join-Path $root 'skills') 'SKILL.md'
            $ag = & $cost (Join-Path $root 'agents') '*.md'
            Write-Host ("RogueKit plugin descriptions: {0} skills ~{1} tok, {2} agents ~{3} tok, every session (bodies load only when used)" -f $sk.Count, $sk.Tok, $ag.Count, $ag.Tok)
        }
        foreach ($n in $names) {
            $det = (Invoke-ClaudeCli @('plugin', 'details', $n)).Output
            $cost = if ($det -match '(?m)Always-on:\s*(.+)$') { $Matches[1].Trim() } else { 'n/a' }
            Write-Host "    $n -> always-on: $cost"
        }
        $ml = (Invoke-ClaudeCli @('mcp', 'list')).Output
        $servers = @($ml -split "`n" | Where-Object { $_ -match '^\S.*:\s' -and $_ -notmatch '^Checking' })
        Write-Host "MCP servers: $($servers.Count) (each adds tool definitions to every session; /context shows real cost)"
        $servers | ForEach-Object { Write-Host "    $($_.Trim())" }
    }
    Write-Host ''
    Write-Host 'Monthly review: keep what you used, remove the rest (claude plugin uninstall <name>, claude mcp remove <name>).'
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
switch ($Action) {
    'Status' { Show-Status; exit 0 }
    'Doctor' { Invoke-Doctor; exit 0 }
    'Audit' { Invoke-Audit; exit 0 }
    'Uninstall' {
        if ((Test-Claude) -and $PSCmdlet.ShouldProcess("$PluginName@$MarketplaceName", 'Uninstall RogueKit plugin and marketplace')) {
            [void](Invoke-ClaudeCli @('plugin', 'uninstall', "$PluginName@$MarketplaceName"))
            [void](Invoke-ClaudeCli @('plugin', 'marketplace', 'remove', $MarketplaceName))
            Write-Host 'Removed RogueKit plugin and marketplace entry.'
        }
        Remove-RulesBlock -WhatIf:$WhatIfPreference
        Write-Host ('Not removed (remove yourself if wanted): MCP servers (claude mcp remove <name>), data folder ' + $DataDir)
        exit 0
    }
}

# Action = Install
Write-Host "Installing $KitName $KitVersion"
if (!$KeepOldPack) { Invoke-OldPackMigration -WhatIf:$WhatIfPreference }
if (!$SkipRules) { Set-RulesBlock -WhatIf:$WhatIfPreference } else { Write-Host 'Skipped rules block (-SkipRules).' }
if (!$SkipPlugin) { Install-KitPlugin -WhatIf:$WhatIfPreference } else { Write-Host 'Skipped plugin (-SkipPlugin).' }
Install-McpServers -Names $McpServers -WhatIf:$WhatIfPreference
if (!$WhatIfPreference) {
    Write-Utf8File -Path (Join-Path $DataDir 'state.json') -Content ((@{ kit = $KitName; version = $KitVersion; installedAt = (Get-Date).ToString('o') } | ConvertTo-Json))
}
Write-Host ''
Write-Host "$KitName $KitVersion install finished. Restart Claude Code (CLI and Desktop) to load it, then run:  .\Install-RogueKit.ps1 -Action Doctor"
