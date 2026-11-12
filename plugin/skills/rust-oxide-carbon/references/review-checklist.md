# Rust plugin review checklist

Run through this on a diff before calling a plugin change done. Mark each item verified, not applicable, or unverified.

**Correctness**
- [ ] Hook names and parameter lists match the target Rust build and framework docs (or are existing code).
- [ ] Return values of `object` hooks are intentional (`null` = continue; non-null blocks or overrides).
- [ ] Null and destroyed checks after any delay, callback, lookup or cast (`entity`, `player`, `item`, `container`).
- [ ] Offline/sleeping/NPC/bot players handled where relevant (`IsConnected`, `userID.IsSteamId()`, `IsNpc`).
- [ ] No Unity/Rust API calls off the main thread.

**Lifecycle**
- [ ] `Unload` removes UI, timers, spawned entities/components, event subscriptions, Harmony patches, cached references.
- [ ] Hot reload twice in a row leaves one copy of everything.
- [ ] `OnServerInitialized` handles plugins loaded after server start (`initial` flag) and players already online.
- [ ] Data is saved on unload, on save events, and not corrupted by partial writes.

**Security and trust**
- [ ] Every command and UI callback checks permission and validates arguments.
- [ ] No client-supplied value used for paths, JSON, SQL, console commands or RCON without validation.
- [ ] No secrets in code, config defaults, examples or logs; no hidden network calls.
- [ ] File access limited to the framework's data/config folders.

**Performance**
- [ ] Hot hooks exit early; no LINQ, closures, scans, string building or reflection on frequent paths.
- [ ] Timers and coroutines have sane intervals and are stopped on unload.
- [ ] Pooled collections are returned to the pool; no unbounded caches.

**Compatibility and release**
- [ ] Config migration keeps the user's existing settings and adds new keys with defaults.
- [ ] Language keys exist for every message; new keys added to the default lang file.
- [ ] Permissions, commands and config options documented.
- [ ] `[Info]` version, changelog and README/store text agree.
- [ ] Oxide and Carbon behaviour stated explicitly if only one was tested.

**Evidence**
- [ ] `dotnet build` of the reference project: result recorded.
- [ ] Loaded on a local test server: compile result, command test, clean reload recorded.
- [ ] Everything not run is listed as an unverified assumption.
