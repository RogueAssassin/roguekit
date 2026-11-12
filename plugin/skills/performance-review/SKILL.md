---
name: performance-review
description: Use for profiling, performance investigations, memory usage, allocations, concurrency, database efficiency and optimisation.
---
# Performance engineering
- Establish the workload, baseline, environment and measurable performance goal before optimising.
- Prefer profiling and measurements over intuition; identify the actual bottleneck.
- Consider CPU, allocations, garbage collection, memory retention, I/O, database queries, contention and network latency.
- Avoid speculative caching or complexity without evidence and a safe invalidation strategy.
- Preserve correctness and observability; compare before/after measurements using equivalent workloads.
- Report trade-offs, measurement limits and regressions checked.
