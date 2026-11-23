# Contributing to RogueKit

## Ground rules
- Keep the pack lean: skills are loaded by description, so keep descriptions short and put detail in `references/` files.
- Shipped scripts must stay safe on managed devices: no `Invoke-Expression`, encoded commands, download cradles, hidden windows, execution-policy changes, `Add-Type`, or persistence. `scripts/Test-RogueKit.ps1` checks this.
- Never commit keys, tokens or personal data. Do not add co-author or tool-attribution trailers.

## Before opening a pull request
```powershell
powershell -NoProfile -File scripts/Test-RogueKit.ps1
claude plugin validate plugin
```
Update `CHANGELOG.md`, `docs/skills.md` and the skill counts in `README.md` and `docs/README.md` when adding or removing a skill (the test checks they agree).

## Adding a skill
Create `plugin/skills/<name>/SKILL.md` with `name` (same as the folder) and a one-sentence `description` that starts with "Use when". Put long material in `references/`.

## Releasing (maintainers)
1. Bump `version` in `plugin/.claude-plugin/plugin.json` and add a matching top entry in `CHANGELOG.md`.
2. Run the self-test and `claude plugin validate plugin`.
3. Commit, tag `vX.Y.Z`, push, and create the GitHub release.
4. Optionally attach the output of `scripts/Test-RogueKit.ps1 -Action Manifest` so IT teams can verify file hashes.
