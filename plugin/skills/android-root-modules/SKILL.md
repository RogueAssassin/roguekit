---
name: android-root-modules
description: Use for Android work on rooted devices: Magisk/KernelSU-style modules, shell scripts run as root, system tweaks (Bluetooth, power, radios), companion apps, update.json feeds, and device compatibility such as Pixel devices.
---
# Android root modules and companion apps

Typical layout: `module/` (module.prop, install/service/post-fs-data scripts), `companion-app/` (Android app), `update.json`, `tests/`, `ARCHITECTURE.md`, `CHANGELOG.md`.

## Safety first (a bad module can bootloop a device)
- Never run anything on a connected device, or `adb shell su`, without explicit approval; prefer read-only inspection (`getprop`, `dumpsys`, `logcat -d`, `ls`) and state what each command changes.
- Module scripts must be **fail-safe**: no unguarded `rm`/`mount`/`setprop` on critical paths, tolerate missing files/properties, never block boot (`post-fs-data` must be fast; heavy work belongs in `service.sh` after boot completes), and include a disable switch (`disable` file or a documented safe-mode/uninstall path).
- Do not weaken SELinux or disable security features as a "fix". Keep changes minimal, reversible and documented.
- Do not suggest bypassing device integrity checks or attestation to make apps work.

## Shell scripts
POSIX `sh`/BusyBox ash (no bashisms unless the interpreter is confirmed), `set -u`, quoted variables, LF endings, absolute paths, logging to a module log file with size cap, idempotent. Check `shellcheck` if available. Detect Android API level, device model and ROM before applying device-specific tweaks (Pixel behaviour differs from other OEMs and across Android releases), and fall back to doing nothing when unsupported.

## Bluetooth, power and radio tweaks
Identify the actual cause first with logs (`logcat -b all -d`, `dumpsys bluetooth_manager`, `btsnoop` if available) and a repeatable symptom. Change one property or setting at a time, record the previous value for restore, and keep the effect measurable (reconnect time, drop count, battery impact). Properties and settings keys differ per Android version: verify they exist on the target version.

## Companion app
Target and compile SDK per the project's Gradle files; request the minimum permissions and explain them; handle Android 12+ Bluetooth runtime permissions and background limits; no network calls or telemetry unless documented; talk to the module through a narrow, validated interface (files or `su` commands with fixed arguments, never user-built shell strings). `./gradlew lint test assembleDebug` to verify; report if no emulator/device was available.

## Updates and releases
`update.json` (version, versionCode, zipUrl, changelog) must match `module.prop`; versionCode strictly increases; publish the zip with a checksum; keep CHANGELOG in step; test install, upgrade and uninstall paths on a spare device when possible. PRs for compatibility fixes should say which devices/Android versions were actually tested.
