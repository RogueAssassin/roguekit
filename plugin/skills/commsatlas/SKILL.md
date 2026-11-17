---
name: commsatlas
description: Use when coding, fixing, building, testing or releasing the CommsAtlas project (comms room, rack and patch documentation platform: ASP.NET Core .NET 10 single-file server, SQLite, plain JavaScript web app, UniFi connector, self-extracting .run installer).
---
# CommsAtlas

Repo: `RogueAssassin/CommsAtlas` (private). Locate the checkout first (`git rev-parse --show-toplevel`); do not assume a path. Read `README.md`, `INSTALL.md` and the newest lines of `BUILD-LOG.md` before large changes.

## Architecture
- `src/`: the web app. **Plain JavaScript, HTML and CSS, no build step, no runtime dependencies.** Modules in `src/js/` (`rack.js`, `ports.js`, `store.js`, `sync.js`, `views.js`, `connectors.js`, `importer.js`, `docimport.js`, `auth.js` ...). Bundled libraries in `src/vendor/` (pdf.js, tesseract); do not edit them.
- `server/`: ASP.NET Core on .NET 10, published as **one single-file program** with the web app embedded. SQLite storage. Files: `Program.cs`, `Db.cs`, `Accounts.cs`, `AuthApi.cs`, `Oidc.cs`, `Tokens.cs`, `Workspaces.cs`, `UnifiInventory.cs`, `Build.cs`.
- `deploy/`: installer/updater, uninstaller, self-extracting header (Linux shell; keep **LF line endings** and POSIX `sh`).
- `build.ps1`: produces `release/CommsAtlas-<build>.run`. `server/wwwroot` is a **build-time copy of `src/`**: never edit it, and do not commit it. `src/config.js` is replaced by a file the server generates from `appsettings.json`.
- Target host: 64-bit Ubuntu/Debian (x64 or arm64) behind nginx. Developing on Windows is normal; keep scripts cross-platform where they run on the server.

## Workflow
1. `git status` and the current branch first. Preserve uncommitted work.
2. Make the smallest change. Frontend: edit `src/` only. Backend: edit `server/` only.
3. Check, cheapest first:
   - `dotnet build server -c Release` (compiler errors and warnings).
   - `dotnet run --project server -- --selftest`: must print `All checks passed.` It starts a private server with a throw-away data folder and exercises every API route, including the UniFi connector against a stand-in console. Add a check here for every new or changed API route.
   - For frontend changes with no test coverage, run the app locally and exercise the screen; say plainly if you could not.
4. Build only when asked: `pwsh ./build.ps1 -Test -Notes "what changed"` (add `-Runtime linux-arm64` for ARM). `-Test` runs the self-test first and stops if it fails. Each build gets a random alphanumeric build number, stamps `version.js`, adds `?b=<build>` to script/style URLs (cache busting) and appends a line to `BUILD-LOG.md`. Write `-Notes` as the user-facing change summary.
5. The "Uploaded" column in `BUILD-LOG.md` is filled in by hand when a build goes to a server. Do not invent it.

## Rules specific to this project
- **Never deploy, upload to the live site, or restart its service without explicit approval.** Report the `.run` path and build number instead.
- **Security-sensitive areas** (accounts, sessions, SSO, two-step codes, tokens, tenants, API body limits, rate limits): earlier reviews fixed approve-endpoint checks, Microsoft tenant pinning, mandatory SSO nonce, sign-up account hijack, session invalidation on password change. Keep those properties; review any change here as a security change and add a self-test.
- **UniFi connector is read-only.** Never read or store a Wi-Fi passphrase. API keys stay encrypted on the server and are never sent to a browser. Pull runs in the background; imports keep the user's own labels, cables and notes and must stay undoable.
- **Multi-tenant**: every workspace query must be scoped to the tenant and the caller's access level (Super Admin, Admin, Editor, Technician, Viewer). Check authorisation on the server, never only in the UI.
- **Data safety**: updates keep data and `appsettings.json`, take a database copy first, keep the previous program, and roll back if the new one does not start. Preserve that behaviour in any installer change. SQLite schema changes need a forward migration that runs on existing databases.
- **No real customer data, keys, passwords or `appsettings.json` secrets** in code, tests, commits or the mock workspace (which is entirely fictional).
- Known UI pitfalls from the build log: re-rendering a form while the user types wipes their input (do not redraw on blur/change); a generic `data-role` attribute collided with another element's handler (use specific attributes); the start page must stay `no-cache`.

## Performance notes
- History is thinned and images/libraries are cached for a week; keep large rack/cable renders from doing full redraws (update the changed rack or cable, not the whole workspace).
- Server: parameterised SQLite queries, batch writes in a transaction, avoid loading whole workspaces for small changes, keep the API body limit.
- Frontend: avoid layout thrash when drawing racks and cable paths (read geometry once, then write); debounce search and drag handlers.
For method and tooling use the `dotnet-csharp`, `sql-database` and `frontend-ui-ux` skills' `references/quality-and-performance.md`.

## Reporting
State the build/test commands actually run and their results, the files changed, and anything unverified (for example UI behaviour not exercised in a browser, ARM build not run, nothing deployed).
