---
name: flutter-dart
description: Use for Flutter and Dart apps and shared Flutter packages (admin tools, customer apps, monorepo foundations): project structure, state management, API clients, testing, analysis and release builds.
---
# Flutter and Dart

## Inspect first
`pubspec.yaml` (SDK constraint, dependencies, workspace/path packages), `analysis_options.yaml`, `flutter --version`, platform folders actually present, the state-management and routing approach already used, and how shared foundation packages are consumed by each app. Match them; do not introduce a second pattern.

## Quality loop (cheapest first)
1. `dart format --output=none --set-exit-if-changed .` (only if the repo enforces formatting)
2. `flutter analyze` (treat new warnings as defects; keep lints from `analysis_options.yaml`)
3. `flutter test path/to/test.dart`, then `flutter test`; add widget tests for UI behaviour and unit tests for logic
4. `flutter build <target>` for the platform you changed when practical
5. `dart pub outdated` / `flutter pub deps` before dependency changes; avoid adding packages without checking maintenance, licence and platform support

## Common error classes
Using `BuildContext` across `await` (check `mounted`), unawaited futures, missing `dispose` of controllers/streams/subscriptions, `setState` after dispose, rebuilding large trees (split widgets, `const` constructors), unbounded lists (`ListView.builder`), null-safety escapes with `!`, platform channel assumptions, timezone/locale handling, secrets compiled into the app.

## Architecture
Keep UI, state and data layers separate; one API client layer with typed models (generated or hand-written consistently), error mapping and retry/timeouts; shared foundation package for theme, auth, networking and widgets so apps (admin, customer) do not diverge. Environment config via `--dart-define`/flavors, never committed secrets. Token storage in secure storage, not shared preferences.

## Performance
Profile in profile mode (DevTools): jank in frame timings, rebuild counts, memory. Typical fixes: `const` widgets, `ListView.builder`/slivers, `RepaintBoundary` where justified, image caching and sizing, move heavy work to isolates (`compute`/`Isolate.run`), debounce inputs, avoid opacity/clip layers in lists.

## Release
Version in `pubspec.yaml` (`version: x.y.z+build`) in step with changelog and any version matrix; signing keys and keystores never in the repo; state which platforms were actually built and tested.
