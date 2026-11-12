---
name: dotnet-csharp
description: Use for C#, .NET, ASP.NET Core, EF Core, Windows desktop applications, libraries, services, and Microsoft development tooling.
---
# .NET and C#
- Inspect solution/project files, target frameworks (.NET 8 / .NET 10), SDK, nullable settings, analyzers and existing architecture first. Use `dotnet build`, `dotnet test`, `dotnet run`.
- Follow the repository's language version and established dependency-injection and service-lifetime conventions.
- Use async/await for asynchronous I/O; avoid sync-over-async and use CancellationToken where appropriate.
- Validate inputs, preserve useful exception context, and use structured logging without secrets.
- Review EF Core query shape, tracking, migrations, transaction boundaries and generated SQL for risky changes.
- Consider Windows-specific lifecycle, process ownership, file locking, permissions and path handling in desktop/server tools.
- Add or update tests using the existing test framework. Run relevant tests, `dotnet build`, and formatting/analyzers when configured.
- Check package compatibility and release notes before upgrading dependencies or target frameworks.
- Before finishing, and whenever asked to find errors or speed something up, read `references/quality-and-performance.md` in this skill: it lists the cheapest verification commands, common error classes, how to measure, and alternatives to try. Measure before changing; report before/after.
