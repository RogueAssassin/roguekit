---
name: rust-oxide-carbon
description: Use for Rust game server development, uMod/Oxide and Carbon plugins, C# extension DLLs, Rust entities, prefabs, hooks, permissions, RCON and server performance.
---
# Rust, Oxide and Carbon development
- Identify the Rust build/protocol context, server framework (uMod/Oxide or Carbon), extension version, plugin version and available assemblies before changing code.
- Verify hook signatures, entity types, prefabs, convars and API behaviour against the supplied/current server assemblies or authoritative framework documentation; do not guess identifiers.
- Preserve compatibility requirements across supported server frameworks and versions. Clearly isolate framework-specific behaviour.
- Minimise hot-path allocations, repeated world/entity queries, reflection, LINQ churn and unnecessary timers. Cache only when invalidation and lifecycle are safe.
- Handle entity destruction, plugin unload/reload, timers, subscriptions, event hooks and references to avoid leaks and stale objects.
- Use correct permissions, input validation, safe file/data handling and server-authoritative logic.
- Consider production server impact. Never deploy, restart or run destructive commands against a live server without explicit approval.
- Run available compile/build checks and inspect logs. Report unverified runtime assumptions separately.
- Keep plugin and extension version numbers, changelog, documentation and CI metadata consistent when a release is requested.
