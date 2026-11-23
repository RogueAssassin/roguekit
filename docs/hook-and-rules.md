# Token-saver hook and global rules

## Token-saver hook (`plugin/hooks/token-guard.ps1`)

A local `PreToolUse` hook for the `Read` and `Bash` tools. Before Claude reads a file or runs a command it checks for known token wasters and, if found, **denies the call with a reason Claude can act on** (for example "read with offset and limit").

| Denied | Why | What Claude does instead |
|---|---|---|
| `Read` of a file over 150 KB with no `limit` | Huge files flood context | Reads a range, or searches first |
| `Read` of lockfiles, `*.min.js`, `*.min.css`, `*.map` | Generated, low value | Reads source files instead |
| `Read` inside `node_modules` or `.git/objects` | Vendored/binary | Skips |
| `git log` with no count or date bound | Unbounded output | Adds `-n 20` or `--since` |

Properties: no network, no storage, no telemetry. If the script errors or the input is unreadable it **allows** the call (fails open). It never rewrites or compresses content.

Settings (environment variables):

| Variable | Effect |
|---|---|
| `ROGUEKIT_TOKEN_SAVER=off` | Disable the hook |
| `ROGUEKIT_READ_MAX_KB=300` | Change the size limit (default 150) |
| `CLAUDEPACK_*` | Legacy names still honoured |

Do not disable it to get past a single denial; follow the message.

## Global rules block

The plugin system cannot ship global instructions, so the installer adds one marked block to `~/.claude/CLAUDE.md`:

```text
<!-- BEGIN ROGUEKIT MANAGED -->
...
<!-- END ROGUEKIT MANAGED -->
```

Everything outside the markers is yours and is never touched. A timestamped backup goes to `~/.roguekit/backups/` before any change; re-running the installer is idempotent ("Unchanged" when nothing differs); `-Action Uninstall` removes only the block. The text is in `rules/global-rules.md` (about 1.3k tokens).

Sections: working with an existing project, implementation quality, verification and reporting, Git and release safety, security and privacy, **model routing** (Sonnet by default, Opus on demand), hard limits (no full-file rewrites for small edits; stop after two identical failures), and collaboration/efficiency.

If a project has its own `CLAUDE.md`, project rules add to these; they do not silently replace them.

## Managed devices

No execution-policy bypass is used, and the script works in PowerShell Constrained Language Mode (saved encrypted keys are not readable there; use the provider environment variable). Set `ROGUEKIT_OFFLINE=1` to disable remote use. See [managed-devices.md](managed-devices.md).
