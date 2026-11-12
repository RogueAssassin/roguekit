# SQL: error prevention and performance alternatives

## Catch errors early
- Identify the engine and version first (SQL Server, PostgreSQL, MySQL/MariaDB, SQLite); syntax and plans differ.
- Run new queries and migrations on a copy or a transaction you roll back; never first-run on production. Show `SELECT` counts before `UPDATE`/`DELETE`, and wrap writes in a transaction with a `WHERE` you have verified.
- Use parameters, never string concatenation (injection). Check collation, NULL handling (`= NULL` vs `IS NULL`, `NOT IN` with NULLs), implicit conversions, time zones, and integer overflow.
- Migrations: reversible where possible, one concern each, safe on large tables (avoid long locks: add nullable column, backfill in batches, then constrain).
- Integrity: constraints and foreign keys in the schema, not only in code.

## Measure first
Get the actual plan: `EXPLAIN (ANALYZE, BUFFERS)` (PostgreSQL), actual execution plan / `SET STATISTICS IO, TIME ON` (SQL Server), `EXPLAIN ANALYZE` (MySQL 8+), `EXPLAIN QUERY PLAN` (SQLite). Compare rows estimated vs actual, scans vs seeks, and I/O, not just elapsed time.

## Alternatives to try
| Problem | Alternatives |
|---|---|
| Full scans | Index matching `WHERE`/`JOIN`/`ORDER BY` (column order matters); covering/included columns |
| Non-sargable filters | Rewrite `WHERE fn(col) = x` to compare the raw column to a computed value; avoid leading-wildcard `LIKE` |
| N+1 from application code | One joined or `IN (...)` query, batching, ORM eager loading |
| Deep `OFFSET` paging | Keyset pagination (`WHERE id > @last ORDER BY id LIMIT n`) |
| `SELECT *` | Select needed columns only |
| Correlated subqueries | Joins, window functions, CTEs (check whether your engine inlines them) |
| Row-by-row loops | Set-based statements, bulk insert/`COPY`/table-valued parameters |
| Hot aggregates | Indexed/materialised views, summary tables refreshed on a schedule |
| Lock contention | Shorter transactions, consistent lock order, appropriate isolation level, batch large writes |
| Stale statistics / bloat | Update statistics, vacuum/analyse or index maintenance on schedule |

Rules: one change at a time, record the plan before and after, and weigh index cost against write load.
