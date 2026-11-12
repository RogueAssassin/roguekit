# RogueKit Token Saver - PreToolUse guard (Read, Bash).
# Local only: reads the hook JSON from stdin, writes at most one JSON decision to stdout.
# Fails OPEN: any error or unrecognised input allows the tool call.
# Disable: set ROGUEKIT_TOKEN_SAVER=off. Size limit: ROGUEKIT_READ_MAX_KB (default 150).
# The legacy CLAUDEPACK_* names are still honoured.
$ErrorActionPreference = 'Stop'

function Deny([string]$Reason) {
    $out = @{ hookSpecificOutput = @{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = "RogueKit token saver: $Reason (set ROGUEKIT_TOKEN_SAVER=off to disable)"
    } }
    [Console]::Out.Write(($out | ConvertTo-Json -Depth 5 -Compress))
    exit 0
}

try {
    if ($env:ROGUEKIT_TOKEN_SAVER -eq 'off' -or $env:CLAUDEPACK_TOKEN_SAVER -eq 'off') { exit 0 }
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $evt = $raw | ConvertFrom-Json
    $tool = [string]$evt.tool_name
    $in = $evt.tool_input
    if ($null -eq $in) { exit 0 }

    $maxKb = 150
    foreach ($v in @($env:ROGUEKIT_READ_MAX_KB, $env:CLAUDEPACK_READ_MAX_KB)) { if ($v -match '^\d+$') { $maxKb = [int]$v; break } }

    if ($tool -eq 'Read') {
        $path = [string]$in.file_path
        if ([string]::IsNullOrWhiteSpace($path)) { exit 0 }
        $ranged = ($null -ne $in.limit) -or ($null -ne $in.pages)
        if ($ranged) { exit 0 }

        $norm = $path -replace '\\', '/'
        $name = [System.IO.Path]::GetFileName($path)

        if ($norm -match '/(node_modules|\.git/objects)/') {
            Deny "'$name' is inside a dependency/VCS-internal folder. Search for the specific symbol instead of reading it."
        }
        if ($name -match '(?i)^(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|poetry\.lock|Cargo\.lock|composer\.lock|packages\.lock\.json)$' -or
            $name -match '(?i)\.(min\.js|min\.css|map)$') {
            Deny "'$name' is a lockfile/minified/source-map file. Use grep for the specific entry, or Read with offset and limit."
        }
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
            # Images, PDFs and notebooks are handled by the Read tool itself.
            if ($ext -notin '.png', '.jpg', '.jpeg', '.gif', '.webp', '.pdf', '.ipynb') {
                $kb = [math]::Round((Get-Item -LiteralPath $path).Length / 1KB)
                if ($kb -gt $maxKb) {
                    Deny "'$name' is $kb KB (limit $maxKb KB) and no line range was given. Grep for what you need, or Read with offset and limit."
                }
            }
        }
        exit 0
    }

    if ($tool -eq 'Bash') {
        $cmd = [string]$in.command
        if ($cmd -match '(^|[;&|]\s*)git\s+log(\s|$)' -and
            $cmd -notmatch '(\s-n\s*\d+|\s-\d+(\s|$)|--max-count|-n\d+|\s--since|\s--after|\s-\d+\b)') {
            Deny "unbounded 'git log'. Re-run with a limit, e.g. git log -n 20 --oneline"
        }
    }
    exit 0
}
catch {
    exit 0
}
