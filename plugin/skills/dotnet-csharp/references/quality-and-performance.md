# C# / .NET: error prevention and performance alternatives

## Catch errors early (cheapest first)
1. `dotnet build -warnaserror` on the changed project (or `dotnet build` and read warnings; do not hide them).
2. `dotnet format --verify-no-changes` (style/analyzer drift) only if the repo already uses `.editorconfig`/format checks.
3. `dotnet test --filter <narrow>` then the full suite.
4. Confirm settings the repo already has; propose, do not silently add: `<Nullable>enable</Nullable>`, `<AnalysisLevel>latest-recommended</AnalysisLevel>`, `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>`, `<TreatWarningsAsErrors>` for new code only.
5. `dotnet list package --vulnerable --include-transitive` and `--outdated` before dependency work.

Typical error classes to check by reading the diff: null deref after `?.`/`!`, `async void`, un-awaited tasks, `.Result`/`.Wait()` (deadlocks), captured loop variables, `IDisposable` not disposed (`HttpClient` per request, streams, `DbContext` lifetime), `DateTime.Now` vs UTC, culture-sensitive parse/format, `Dictionary` mutated while enumerated, shared mutable state in singletons, swallowed exceptions, `catch (Exception)` without logging.

## Measure first
- Micro: BenchmarkDotNet (Release build, realistic data, `[MemoryDiagnoser]`).
- Process: `dotnet-counters monitor`, `dotnet-trace collect`, `dotnet-gcdump`; Visual Studio/Rider profilers.
- Report allocations and Gen0/1/2 counts, not just time.

## Alternatives to try (only where measurement points)
| Problem | Alternatives |
|---|---|
| Allocation-heavy string work | `string.Create`, `Span<char>`/`ReadOnlySpan<char>`, `StringBuilder` (reuse), `stackalloc` for small bounded buffers, interpolated-string handlers |
| Temporary arrays/lists | `ArrayPool<T>.Shared`, pre-sized `List<T>(capacity)`, `CollectionsMarshal.AsSpan` |
| Hot LINQ | Plain `for`/`foreach` loop; avoid repeated `ToList()`/`Count()` ; `TryGetNonEnumeratedCount` |
| Lookup-heavy read-only data | `FrozenDictionary`/`FrozenSet`, `HashSet<T>` instead of `List.Contains` |
| Regex/JSON | `[GeneratedRegex]`, `System.Text.Json` source generation, reuse `JsonSerializerOptions` |
| Async overhead | `ValueTask` for hot, often-synchronous paths; `ConfigureAwait(false)` in libraries; avoid `Task.Run` around I/O |
| Parallel work | `Parallel.ForEachAsync` with a bounded `MaxDegreeOfParallelism`; `Channel<T>` for producer/consumer |
| Small immutable data | `readonly record struct`/`struct` (only when small and not boxed) |
| Locking contention | `Interlocked`, `ConcurrentDictionary.GetOrAdd` with factory care, `ReaderWriterLockSlim`, reduce sharing |
| EF Core | `AsNoTracking`, projection with `Select`, `AsSplitQuery`, compiled queries, `ExecuteUpdate/ExecuteDelete`, batching, indexes; look at generated SQL, avoid N+1 |
| Startup | ReadyToRun/tiered PGO, trim unused DI registrations, lazy init |

Rules: one change at a time, keep the old version for comparison, state the measured gain and the readability cost, and do not use unsafe code or `stackalloc` without a bound and a test.
