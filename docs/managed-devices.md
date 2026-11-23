# Using RogueKit on managed or work devices

**Important:** RogueKit cannot guarantee compatibility with any specific endpoint-protection product (for example SentinelOne) or organisational policy, and it does not try to evade them. Have your IT or security team review it before use on a work device. This page gives them what they need.

## What RogueKit does
- Copies Markdown skills, agent definitions, one hook script and a few PowerShell helpers into Claude Code's plugin folder (via `claude plugin install`). The optional `Install-RogueKit.ps1` also edits your user `CLAUDE.md` between marked comments.
- No admin rights, services, scheduled tasks, startup entries, registry changes, drivers or downloads.
- No execution-policy changes. Hook and helpers run as `powershell -NoProfile -NonInteractive -File ...`. If policy blocks unsigned scripts, the hook simply does not run (Claude Code carries on) and the skills still work.
- Scripts avoid patterns that security tools commonly flag: no `Invoke-Expression`, encoded commands, download cradles, base64 decoding, hidden windows, `Add-Type` or policy bypass. `Test-RogueKit.ps1` enforces this.
- Scripts work in PowerShell Constrained Language Mode, with reduced features (saved DPAPI keys cannot be read there; use an environment variable).

## Network use
| Script | Contacts | Sends |
|---|---|---|
| `token-guard.ps1` (hook) | nothing | nothing |
| `lookup.ps1` | registry.npmjs.org, pypi.org, api.nuget.org, search.maven.org, crates.io, api.osv.dev, endoflife.date, api.github.com | package names, versions, product names |
| `ask-free.ps1` | only the provider you choose (Groq, OpenRouter, Gemini, NVIDIA, Mistral, GitHub Models, Cerebras, or a local Ollama/LM Studio) | the text you pass it |

Nothing runs in the background; scripts act only when invoked.

## Recommended settings for a work device
- Set `ROGUEKIT_OFFLINE=1` (user environment variable) to disable all remote lookups and remote models. Localhost model servers still work.
- **Do not use `free-model-assist` with work code or data** unless your organisation approves that provider. It sends text to third parties.
- Prefer installing only the plugin (`claude plugin marketplace add` then `claude plugin install roguekit@roguekit`) and skip the optional installer.

## Verifying files
`powershell -File scripts/Test-RogueKit.ps1 -Action Manifest` prints a SHA-256 for every file so IT can review or allow-list a specific release. The repository's self-test runs offline and changes nothing on the machine.
