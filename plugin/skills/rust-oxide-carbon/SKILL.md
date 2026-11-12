---
name: rust-oxide-carbon
description: Use for Rust (Facepunch, Unity) dedicated server plugin development in C#: uMod/Oxide and Carbon plugins, Harmony patches, hooks, entities, prefabs, permissions, config/data/lang files, IDE project setup (Visual Studio, Rider, VS Code), build diagnostics, and server performance. Not for the Rust programming language.
---
# Rust game server plugins (Oxide and Carbon)

"Rust" here is the Facepunch game, built on **Unity** and written in **C#**. Server code runs on Unity's Mono runtime, and almost all game logic runs on the **main thread**. Do not confuse it with the Rust language; if the project is Cargo/`.rs`, this skill does not apply.

## Languages
- **C# is the only target.** Oxide once supported Lua, JavaScript, CoffeeScript and Python through extensions, but they are legacy and unmaintained. Do not write them, and do not suggest them unless the user is maintaining an old plugin.
- **Oxide/uMod**: C# compiled at runtime on the server by Oxide's own compiler. Its language level and namespace allow-list can lag behind the IDE, so treat anything newer than the project already uses as untested until it loads on a real server.
- **Carbon**: C# plugins compiled at runtime, with a modern language level (C# 10+ syntax per its docs; confirm the level your Carbon build accepts), plus the **Harmony** patching library. Carbon also loads Oxide-style plugins through a compatibility layer.

## First, identify the target (ask or inspect, do not guess)
1. Framework: Oxide/uMod, Carbon-native, or **both** (one `.cs` file with conditional sections). Look at the base class (`RustPlugin` vs `CarbonPlugin`) and the namespace (`Oxide.Plugins` vs `Carbon.Plugins`).
2. Rust server build and framework version. Hooks and Facepunch types change between forced wipes and monthly updates.
3. Whether reference assemblies exist locally (see `references/ide-setup.md`). If they do not, say so and mark every signature you cannot verify.

## Non-negotiable rules
- **Verify, never invent.** Hook names/signatures, entity members, prefab paths and convars must come from the referenced assemblies, the uMod or Carbon hook documentation, or code already in the repo. If you cannot verify one, say so and show how to check it (decompile `Assembly-CSharp.dll`, or search the docs).
- **Hook return values matter.** Returning `null` lets default behaviour continue; returning a non-null value usually blocks or overrides it. Return the right type from `object`-returning hooks, and never return `true`/`false` by habit.
- **Main thread only.** Unity and Rust APIs are not thread-safe. Do not touch entities, `BasePlayer`, `Item` or `GameObject` from `Task`, `ThreadPool` or timers' background callbacks. Marshal back with the framework's main-thread facilities, and use async only for file/web work.
- **Lifecycle cleanup.** On `Unload`: destroy UI (`CuiHelper.DestroyUi`) for online players, kill entities and `GameObject`/`MonoBehaviour` components the plugin added, destroy timers, close subscriptions, remove Harmony patches, save data. A reload must leave no stale state and no duplicate hooks.
- **Check entity validity.** After any delay, callback or lookup, test `entity != null && !entity.IsDestroyed` (and `player.IsConnected` where it matters) before use.
- **Server-authoritative.** Never trust client-sent values (chat, console command args, UI input). Validate, clamp and permission-check on the server.
- **Permissions**: register with the plugin prefix (`permission.RegisterPermission("myplugin.use", this)`), check with the player's `UserIDString`, and document each permission.
- **Config/data/lang**: typed config class with `LoadDefaultConfig`, version migration on load, never overwrite a user's edited config silently; localisable messages via the lang API; data files via the framework's data file system.
- **No telemetry, no hidden network calls, no obfuscation.** Server owners read plugins before running them.

## Performance (hot paths)
Hooks such as `OnTick`-like, `OnEntityTakeDamage`, `CanBuild`, `OnPlayerInput`, `OnEntitySpawned` and `OnItemAddedToContainer` fire very often.
- Return early with cheap checks first (type checks, permission lookups cached by player).
- Avoid LINQ, closures, string concatenation/`string.Format`, `GetComponent` and `FindObjectsOfType`/`BaseNetworkable.serverEntities` scans per call. Use pooled lists (`Pool` API; its signature has changed across builds, so verify) and reuse collections.
- Prefer `timer.Once`/`timer.Every` sparingly with sensible intervals; use `InvokeHandler` or coroutines for spread-out work, and batch large jobs across frames.
- Measure before optimising (Carbon and Oxide both expose hook/plugin timing via console commands; confirm with the framework's `help`).

## Working from the IDE
When Claude Code is connected to an IDE (`/ide`), use the context it provides instead of asking the user to paste:
- The **open file** and **selection** are the user's focus. Treat a selection as the exact scope of the request.
- **Diagnostics** from the IDE (red squiggles, build errors) are evidence. Read the error code and file/line, then map it with the table in `references/ide-setup.md`. The most common Rust-plugin causes are a missing reference DLL (`CS0246`), a wrong hook signature (`CS1061`, `CS0115`) and a language-level mismatch (`CS8xxx`).
- Edit the file in place with a minimal diff; the IDE reloads it. Do not reformat the whole file.
- IDE builds only prove the code *type-checks against the referenced DLLs*. They do not prove runtime compile on Oxide/Carbon or correct behaviour. Say which level was checked.

Project scaffolding for Visual Studio, Rider and VS Code (a reference-only `.csproj`, `.editorconfig`, `.gitignore` that excludes Facepunch DLLs, build task) is in `references/ide-setup.md`. Plugin skeletons for Oxide, Carbon and dual-framework files are in `references/plugin-templates.md`. The pre-merge checklist is in `references/review-checklist.md`. Read them only when needed.

## Verification
- Build check: `dotnet build` on the reference project, if one exists. Report warnings that point at API misuse.
- Runtime check: load on a **local test server**, watch the console for compile errors, run the plugin's commands, then `reload` it and confirm clean unload.
- Never deploy to, restart, or run commands on a live server without explicit approval. Do not put RCON passwords or API keys in plugin code, examples or commits.
- Report separately what was compiled, what was run, and what is an unverified runtime assumption.
- Release hygiene: keep the `[Info]` version, changelog, README/uMod page text and CI metadata consistent.
