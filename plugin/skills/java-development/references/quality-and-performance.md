# Java: error prevention and performance alternatives

## Catch errors early
1. Compile with warnings visible: Maven `mvn -q compile` (add `-Xlint:all` via `maven-compiler-plugin` `compilerArgs` if the repo allows), Gradle `./gradlew compileJava`.
2. Run the narrowest test first (`mvn -Dtest=ClassName test`, `./gradlew test --tests Class`), then the module, then everything.
3. Use static analysis the repo already configures (Checkstyle, SpotBugs, PMD, Error Prone, SonarLint). Suggest, do not force, new ones.
4. Dependency checks: `mvn dependency:tree`, `mvn versions:display-dependency-updates`, OWASP dependency-check if configured.
5. Never add wildcard imports.

Error classes to look for in the diff: `NullPointerException` paths (use `Optional` at API edges, `Objects.requireNonNull`), `equals`/`hashCode` mismatch, mutable shared state without synchronisation, `SimpleDateFormat` shared across threads, resource leaks (use try-with-resources), swallowed `InterruptedException`, `==` on boxed values/strings, unchecked casts, open transactions/lazy-loading outside a session, catching `Throwable`.

## Measure first
- Micro: JMH (never hand-rolled `System.nanoTime` loops).
- Runtime: JFR (`-XX:+FlightRecorder` / `jcmd <pid> JFR.start`), async-profiler, `jstack` for contention, GC logs (`-Xlog:gc*`), heap dump for leaks.

## Alternatives to try
| Problem | Alternatives |
|---|---|
| String building in loops | `StringBuilder`, `String.join`, text blocks for constants |
| Boxing in hot paths | Primitive streams (`IntStream`) or plain loops; primitive collections only if a library is already present |
| Stream overhead on tiny/hot collections | Simple `for` loop; avoid repeated `stream()` over the same data |
| Repeated lookups | `HashMap`/`EnumMap`/`EnumSet`; precompute `Map` instead of `list.stream().filter` |
| Blocking I/O concurrency | Virtual threads (Java 21+) or bounded executors; avoid unbounded thread pools |
| Object churn | Reuse immutable objects, `records` for value carriers, avoid needless defensive copies |
| Regex | Precompile `Pattern` as `static final` |
| Database | Fetch joins/`@EntityGraph`, projections/DTOs, batch size, pagination, indexes; look for N+1 in logs (`hibernate.show_sql` temporarily) |
| Caching | Caffeine with explicit size/TTL and an invalidation story; no unbounded `HashMap` caches |
| Startup/memory | Class-data sharing, lazy beans, right-size heap; change JVM flags only with GC-log evidence |

Rules: preserve behaviour, keep the baseline, report numbers with the JVM version and flags.
