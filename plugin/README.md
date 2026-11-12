# roguekit (plugin)

Skills, agents and a local token-saver hook for Claude Code, part of the RogueKit toolkit. It contains 20 on-demand skills (engineering workflows, language guidance, token and context management), five agents (Sonnet by default, Opus for architecture and stubborn bugs) and a `PreToolUse` hook that blocks oversized or generated-file reads and unbounded `git log`. The hook makes no network requests and stores nothing; set `ROGUEKIT_TOKEN_SAVER=off` to disable it.

Install, usage and the optional global rules block are documented in the repository README at the repo root.