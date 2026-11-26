# Design foundations: what makes a page look professional

Use the project's existing tokens and components first. Introduce these only where none exist.

## Tokens before pages
Define once as CSS variables (or the framework theme): spacing, type sizes, colours, radii, shadows, durations, easings. Hard-coded one-off values are the main source of an "assembled" look.

```css
:root {
  --space-1: .25rem; --space-2: .5rem; --space-3: .75rem; --space-4: 1rem;
  --space-6: 1.5rem; --space-8: 2rem; --space-12: 3rem; --space-16: 4rem;
  --text-sm: .875rem; --text-base: 1rem; --text-lg: 1.25rem;
  --text-xl: clamp(1.5rem, 1.2rem + 1.2vw, 2rem);
  --text-2xl: clamp(2rem, 1.4rem + 2.4vw, 3.25rem);
  --radius-sm: 6px; --radius-md: 10px; --radius-lg: 16px;
}
```

## Hierarchy
- Each screen has one primary action. Secondary actions are visibly quieter; destructive ones are separated.
- Rank with size, weight, colour strength and space, using as few of these at once as will do the job.
- Squint test: blur the screenshot; the order you notice things should match their importance.

## Spacing and layout
- Space inside a group is smaller than space between groups. This does more than boxes and dividers.
- Align to a shared grid and shared edges; fix near-misses of a few pixels.
- Give content a maximum width; keep reading text around 45-75 characters per line.
- Avoid card-in-card nesting and a border around everything.
- Use container queries for components that appear in different widths.

## Typography
- One or two families, two or three weights. Body at least 16px, line height about 1.5; headings tighter (1.1-1.25).
- `text-wrap: balance` on headings, `text-wrap: pretty` on paragraphs; `font-variant-numeric: tabular-nums` for tables and counters.
- Load fonts with `font-display: swap` and a metric-matched fallback to avoid layout jumps.

## Colour and depth
- Mostly neutrals, one accent used for action and selection, plus status colours that are never the only signal.
- Contrast (WCAG 2.2 AA): 4.5:1 text, 3:1 large text and control boundaries/focus indicators.
- Design dark mode as its own palette (raise surfaces by lightness, soften saturated colours), not an inversion.
- Shadows imply one light source; use a small set of levels. Nested corner radius = outer radius minus padding.

## Imagery and icons
- One icon set, consistent stroke and size; label icons that are not universally understood.
- Set `width`/`height` or `aspect-ratio` on media; crop consistently.

## Signs of a generic or unfinished page
Everything centred; equal weight everywhere; three identical feature cards by default; gradient on everything; emoji as icons; placeholder copy; inconsistent radii and button heights; default blue focus ring next to a custom palette removed instead of restyled.
