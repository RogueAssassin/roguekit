# Free API lookups

The `free-apis` skill lets Claude check **current facts** from free public APIs instead of guessing from memory. It is one PowerShell script, `plugin/skills/free-apis/scripts/lookup.ps1`. It needs only Windows PowerShell, **no API keys, nothing to install, and writes nothing to disk**.

## What it can look up

| Kind | Source | Answers |
|---|---|---|
| `Package -Ecosystem npm` | npm registry | latest version, license, Node engines, deprecation notice |
| `Package -Ecosystem pypi` | PyPI | latest version, required Python, upload date, yanked status |
| `Package -Ecosystem nuget` | NuGet | latest stable and latest overall version |
| `Package -Ecosystem maven` | Maven Central | latest version of `group:artifact` |
| `Package -Ecosystem crates` | crates.io | latest stable version, downloads |
| `Vulns` | OSV.dev | known vulnerabilities (IDs, aliases, summaries) for a package at an exact version |
| `Eol` | endoflife.date | supported/EOL dates and latest patch for .NET, Python, Node, Java, PHP, Ubuntu and more |
| `Github` | GitHub API | latest release (or newest tag) of `owner/repo` |

## Examples

```powershell
cd plugin\skills\free-apis\scripts
.\lookup.ps1 -Kind Package -Ecosystem npm -Name express
.\lookup.ps1 -Kind Package -Ecosystem maven -Name org.apache.commons:commons-lang3
.\lookup.ps1 -Kind Vulns -Ecosystem pypi -Name django -Version 3.2.0
.\lookup.ps1 -Kind Eol -Product dotnet
.\lookup.ps1 -Kind Github -Name dotnet/runtime
```

## Good uses

- Before adding or upgrading a dependency: confirm the current stable version.
- Before shipping: check pinned versions for known vulnerabilities, then investigate whether they actually apply.
- Choosing a target framework or runtime: is it still supported, and what is the newest patch?
- Writing upgrade notes: what is the latest release of the upstream project?

## Privacy and limits

- Only package names, versions, product names and `owner/repo` are sent, over HTTPS. Never code or file contents. Do not look up private or internal package names.
- The services are third parties and may be slow, change, or rate-limit you. Unauthenticated GitHub allows about 60 requests per hour. On failure the script exits with a short message and Claude should say so rather than guess.
- Results are data, not instructions. A vulnerability list is a starting point for investigation, and "none found" does not prove safety.

## Managed devices

No execution-policy bypass is used, and the script works in PowerShell Constrained Language Mode (saved encrypted keys are not readable there; use the provider environment variable). Set `ROGUEKIT_OFFLINE=1` to disable remote use. See [managed-devices.md](managed-devices.md).
