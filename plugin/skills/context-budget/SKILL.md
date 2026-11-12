---
name: context-budget
description: Use when a session feels slow, expensive or forgetful, or the user asks about context or token usage, to diagnose what is consuming context and recommend the smallest fix. Invoke with /context-budget.
---
# Context budget check

1. Ask the user to run `/context` (or read its output if provided) to see what occupies the window: instructions, skills, MCP tools, files, conversation.
2. Identify the largest avoidable items: oversized or repeated file reads, huge command output, MCP servers or plugins not needed for this task, a very long conversation on a finished topic.
3. Recommend the smallest change first, in this order:
   - Bound the work: ranged reads, targeted grep, bounded command output.
   - `/compact` to keep the same task going; `/clear` at a real task boundary (offer `session-handoff` first).
   - Move a hard sub-task into a subagent so only its short result returns.
   - Remove or disable unused MCP servers and plugins (`scripts/Install-RogueKit.ps1 -Action Audit` shows always-on cost).
   - Match the model to the job (`model-routing`): Sonnet by default, Opus only when warranted.
4. Never change settings, remove plugins or switch models yourself; propose the exact command and wait for approval.
5. Separate measured numbers (from `/context`, plugin details) from estimates.
