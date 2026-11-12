---
name: game-server-tooling
description: Use for dedicated game server managers, installers, configuration presets, SteamCMD, RCON, process lifecycle, logs and Windows server operations, including Rust, DayZ and ARK.
---
# Dedicated game server tooling
- Identify the game, server distribution, mod framework, supported versions and deployment layout first.
- Treat production servers as high impact: inspect before acting and obtain approval before restart, update, deletion or live deployment.
- Handle process ownership and shutdown carefully; do not kill unrelated processes based only on executable name.
- Make install/update operations resumable and idempotent; validate downloads, archives, paths and required files.
- Keep ports, configuration, presets and per-server settings isolated; detect conflicts before changing them.
- Use RCON/API interfaces according to documented protocol behaviour; handle timeouts, authentication and reconnects safely.
- Rotate logs with bounded retention and preserve diagnostics needed to troubleshoot failures.
- Test packaging and upgrade paths, not just compilation. Document recovery and rollback steps.
