# Python: error prevention and performance alternatives

Always use the project's interpreter first: `.venv\Scripts\python.exe` if present, never a global scan.

## Catch errors early
1. Syntax/import check: `python -m compileall -q <pkg>`; run with `python -X dev -W error::DeprecationWarning` when debugging.
2. Lint/format with what the repo uses (ruff, flake8, black, isort). If none, `ruff check` is a safe suggestion, not a forced change.
3. Types: `mypy`/`pyright` on changed modules if configured; add annotations to new public functions.
4. Tests: `pytest -x -q path::test_name`, then the module, then all. Check `pytest --lf` after fixes.
5. Dependencies: `pip list --outdated`, `pip-audit` if available; pin via the repo's mechanism (requirements, pyproject, uv lock).

Error classes: mutable default arguments, late-binding closures in loops, bare `except:`, catching and ignoring, `is` on literals, naive vs aware `datetime`, text/bytes and encoding (`open(..., encoding="utf-8")`), unclosed files/sockets (`with`), `subprocess` with `shell=True` and untrusted input, `pickle`/`yaml.load` on untrusted data, shared state across threads, `asyncio` blocking calls, path handling on Windows (`pathlib`).

## Measure first
- `timeit`/`pyperf` for micro; `cProfile` + `snakeviz`/`pstats` for CPU; `py-spy` for a running process; `scalene` for CPU/memory; `tracemalloc` for allocations.
- Profile with realistic data size and warm caches; report wall time and peak memory.

## Alternatives to try
| Problem | Alternatives |
|---|---|
| Membership tests on lists | `set`/`dict`; sort once + `bisect` |
| Building big lists | Generators / `itertools`; `"".join(parts)` instead of `+=` |
| Repeated pure computation | `functools.lru_cache` / `cache` (bounded, hashable args) |
| Many small objects | `__slots__`, `dataclass(slots=True)`, tuples/`NamedTuple` |
| Tight numeric loops | NumPy vectorisation, Polars/pandas column ops; only then Numba/Cython |
| CPU-bound parallelism | `concurrent.futures.ProcessPoolExecutor`/`multiprocessing`; threads do not help CPU-bound pure Python |
| I/O concurrency | `asyncio` with async libs, or `ThreadPoolExecutor` for blocking I/O |
| JSON/serialisation | `orjson`/`msgspec` if allowed; avoid re-parsing |
| Big files | Stream/iterate lines or chunks, `csv` module, avoid `read()` of everything |
| Regex | Compile once (`re.compile`) at module level |
| Database | Batched inserts, server-side filtering, avoid ORM N+1 (`select_related`/`selectinload`) |
| Startup | Lazy imports for heavy modules in CLIs |

Rules: correctness and readability first; keep the baseline; do not add compiled dependencies for a speedup you have not measured.
