---
name: frontend-ui-ux
description: Use for building or polishing web pages and UI: professional visual design, natural interaction and motion, forms, states, accessibility, responsive layout, React and TypeScript.
---
# Frontend and UI/UX

## Workflow
1. Inspect the framework, design system, tokens and existing components. Preserve them; do not replace a design system without a clear reason.
2. Name the user, their main task and the one primary action of the screen before styling.
3. Look at the current page (screenshot) so changes are judged against it.
4. Build in order: content and structure, layout and spacing, type, colour, states, then motion.
5. Verify in a real browser at desktop and phone widths; otherwise state what was not visually verified.

## Load when needed (in this skill folder)
- `references/design-foundations.md`: tokens, hierarchy, spacing, type, colour. Read for any new or "make it look professional" work.
- `references/natural-interaction.md`: feedback, motion timing and easing, forms, states, microcopy. Read for "make it feel natural/smooth" work.
- `references/ui-review.md`: browser review pass, scoring and report format. Read when reviewing or before calling a page done.
- `references/quality-and-performance.md`: verification commands, common errors, speed. Measure before changing.

For a new visual direction (style, personality), also use the `frontend-design` skill if installed. For an independent review, use the `ui-reviewer` agent.

## Done means
- Works at 375px and 1440px without horizontal scroll; keyboard usable with visible focus; WCAG 2.2 AA contrast.
- Loading, empty, error and success states exist where relevant; reduced motion respected.
- No new console errors; no unnecessary dependencies or client-side JavaScript.
