# Free model assist

Let Claude hand small side tasks to **free or local model APIs** to save your Claude usage. It is one PowerShell script, `plugin/skills/free-model-assist/scripts/ask-free.ps1`, driven by the `free-model-assist` skill.

**What it needs:** only the Windows PowerShell that comes with Windows (5.1 or newer). No Python, Node, proxy, server or background process. **What it changes:** nothing, unless you choose to run `SaveKey` or `SaveDefault` yourself. Nothing is installed, no environment variable is created, no settings are edited.

**What it is not:** a way to run Claude Code itself on other models. Claude (or whichever model you run Claude Code with) stays in charge and decides what to delegate. Free models see only the text sent to them, never your files, and their answers are untrusted drafts to be checked.

## Providers

The script knows these OpenAI-compatible services by name. It stores **base URLs and key variable names only**: no model IDs and no quota numbers, because both change often. Check each provider's page for current limits and terms, and list real model IDs with `ListModels`.

| Name | Key variable (optional) | Get a key | Notes |
|---|---|---|---|
| `groq` | `GROQ_API_KEY` | console.groq.com | Fast; free tier with daily caps |
| `openrouter` | `OPENROUTER_API_KEY` | openrouter.ai | Many models; free ones have `:free` IDs and tight caps |
| `gemini` | `GEMINI_API_KEY` | aistudio.google.com | Google AI Studio free tier; check data-use terms |
| `nvidia` | `NVIDIA_API_KEY` | build.nvidia.com | Hosted trial access to open models |
| `mistral` | `MISTRAL_API_KEY` | console.mistral.ai | Free experimentation tier |
| `github` | `GITHUB_MODELS_TOKEN` | github.com/marketplace/models | GitHub Models, rate limited |
| `cerebras` | `CEREBRAS_API_KEY` | cloud.cerebras.ai | Free access has changed; confirm current terms |
| `ollama` | none | ollama.com | Local and private; needs Ollama already running |
| `lmstudio` | none | lmstudio.ai | Local; needs LM Studio's server running |
| `custom` | `CUSTOM_API_KEY` | any | Use with `-BaseUrl https://host/v1` |

Local providers are used only if you already run them. RogueKit never installs them.

## Setup (once, in your own terminal)

```powershell
cd plugin\skills\free-model-assist\scripts
.\ask-free.ps1 -Action SaveKey -Provider groq          # hidden prompt; stored encrypted for your Windows user
.\ask-free.ps1 -Action ListModels -Provider groq        # pick a real model id
.\ask-free.ps1 -Action SaveDefault -Target groq/<model-id>   # optional
.\ask-free.ps1 -Action Status                           # shows key sources, never values
```

Keys live in `~/.roguekit/keys/<provider>.key`, encrypted with Windows DPAPI so only your Windows account can read them; delete the file to remove a key. If you prefer, set the provider's environment variable yourself instead; the script only reads it. You can run it without any key against local providers.

## Using it

Ask Claude naturally ("summarise this log with a free model", "get a second opinion from the free models") or run it yourself:

```powershell
.\ask-free.ps1 -Target groq/<model>,openrouter/<model>:free -System "Be brief." -Prompt "Summarise: ..."
Get-Content notes.txt | .\ask-free.ps1 -Target groq/<model>
.\ask-free.ps1 -Target groq/<model> -Prompt "..." -DryRun     # shows size and destination, sends nothing
```

Targets are tried in order. A 429 or 5xx is retried briefly (honouring `Retry-After` up to 10 seconds), then the next target is used.

## Safety built in

- Remote hosts must be **HTTPS**; plain HTTP only for localhost.
- Prompts that look like secrets (private keys, cloud/API tokens, `password = ...`) are **refused** unless you pass `-AllowSecrets`.
- Prompts over 60,000 characters are refused (free models have small contexts).
- Keys are never printed, logged or placed on a command line; error messages never include them.
- Nothing is sent unless an `Ask` is actually run, and `-DryRun` previews.
- The skill instructs Claude to ask you before first use and before sending project content, and to treat replies as unverified.

## Privacy

Free tiers may keep prompts or use them to improve models. Send only text you are comfortable sharing: no credentials, customer or personal data, or private source you have not cleared. For sensitive material use a local model.

## Limits to expect

Free models are weaker than Claude, have small contexts and cannot use your tools or files. Quotas and availability are set by the provider and change. Use them for drafts, summaries and second opinions, and verify the results.

## Managed devices

No execution-policy bypass is used, and the script works in PowerShell Constrained Language Mode (saved encrypted keys are not readable there; use the provider environment variable). Set `ROGUEKIT_OFFLINE=1` to disable remote use. See [managed-devices.md](managed-devices.md).
