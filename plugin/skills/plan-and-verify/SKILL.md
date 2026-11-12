---
name: plan-and-verify
description: Use for a non-trivial feature, bug fix or refactor where a plan, a failing test first, an independent review and final verification would prevent rework. Invoke with /plan-and-verify.
---
# Plan, test, implement, review, verify

Use proportionally: skip steps that add nothing for a small change.

1. **Plan.** State the goal, constraints, files likely touched, risks and how success will be checked. For a substantial change, show the plan and wait for the user's go-ahead before editing.
2. **Reproduce / test first.** For a bug, write or run a test that fails for the right reason and record the failure. For a feature, add the narrowest test that pins the new behaviour. If the project has no test setup, say so and define a manual check instead.
3. **Implement.** Smallest change that makes the test pass. No unrelated cleanup, no full-file rewrites.
4. **Review from fresh context.** Delegate to the `code-reviewer` agent (Sonnet) with the diff and the plan; do not review your own change in the same context. Fix real findings, add a regression test for each fixed bug.
5. **Verify.** Run the narrowest relevant tests, then the build/lint/type checks the project already uses. Report what ran and what passed. Never claim a check passed that you did not run.
6. **Close out.** Summarise changes, files, checks run and open risks. Offer `session-handoff` if work continues later.

Stop rule: if the same failure survives 2 consecutive attempts, stop and ask the user, or escalate per `model-routing`.
