# TypeScript / frontend: error prevention and performance alternatives

## Catch errors early
1. Type check: `npx tsc --noEmit` (use the repo's script if present, e.g. `npm run typecheck`). Prefer `strict` for new code; never add `any`/`@ts-ignore` to silence an error without a comment saying why.
2. Lint: `npm run lint` / `npx eslint <changed files>`; format with the repo's Prettier/Biome setup only.
3. Tests: `npx vitest run <file>` or `npx jest <file>`, then the suite; component tests with Testing Library; e2e (Playwright) only for flows.
4. Build: `npm run build` catches import/bundler errors that `tsc` misses.
5. Accessibility: lint rules (jsx-a11y), keyboard pass, contrast, focus order; automated axe check if configured.
6. `npm audit` / `npm outdated` before dependency work; prefer the lockfile's package manager.

Error classes: missing `key` or unstable keys, stale closures in `useEffect`/handlers, missing/over-broad effect dependencies, setState during render, unmounted-component updates, un-awaited promises, `null`/`undefined` from API data without validation (validate at boundaries, e.g. zod), SSR/CSR mismatches (`window` access), unescaped HTML (`dangerouslySetInnerHTML`), secrets in client bundles.

## Measure first
Lighthouse / Web Vitals (LCP, INP, CLS), browser Performance panel, React DevTools Profiler, bundle analyzer (`vite-bundle-visualizer`, `webpack-bundle-analyzer`, `next build` output).

## Alternatives to try
| Problem | Alternatives |
|---|---|
| Re-render storms | Lift/colocate state, split components, `React.memo`, `useMemo`/`useCallback` only where profiling shows benefit, selector-based stores |
| Long lists | Virtualisation (`@tanstack/react-virtual`), pagination |
| Large bundles | Route/component code splitting (`lazy`/dynamic import), tree-shakeable imports, drop heavy deps (date/utility libs) |
| Slow loads | Image formats/sizes + lazy loading, font subsetting + `font-display`, preload critical assets, caching headers |
| Data fetching | Request dedupe/caching (TanStack Query), debounce inputs, avoid waterfalls, server components/SSR where the framework supports it |
| Layout jank | Reserve space for media, avoid layout thrash, animate `transform`/`opacity` |
| Expensive compute | Web Worker, memoised selectors, move to the server |

Rules: measure on a throttled profile, keep accessibility intact, report before/after numbers.
