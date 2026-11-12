---
name: sql-database
description: Use for relational databases, SQL queries, schema design, migrations, indexing, transactions and data integrity.
---
# SQL and database development
- Identify database engine/version and inspect schema, constraints, indexes and migration conventions.
- Parameterise queries and select explicit columns where practical.
- Review query plans and access patterns for performance-sensitive operations.
- Consider transaction scope, isolation, locking, concurrency and referential integrity.
- Treat destructive migrations and production data changes as high risk; require explicit approval.
- Test migrations against representative non-production data and avoid exposing personal data in logs.
- Before finishing, and whenever asked to find errors or speed something up, read `references/quality-and-performance.md` in this skill: it lists the cheapest verification commands, common error classes, how to measure, and alternatives to try. Measure before changing; report before/after.
