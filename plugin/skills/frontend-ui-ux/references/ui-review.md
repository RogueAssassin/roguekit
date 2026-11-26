# Reviewing a page in a real browser

Needs a browser tool (the Playwright plugin/MCP, or the one built into the app). Without one, review the code and say that nothing was visually verified. Stay on localhost or pages the user named; do not submit forms or change data on live sites without permission.

## Pass
1. Resize to 1440x900, 768x1024 and 375x812; screenshot each. Also dark mode and reduced motion if supported.
2. Console errors and failed requests.
3. Keyboard only: Tab through the main task; check order, visible focus, Escape, nothing trapped or unreachable.
4. Accessibility snapshot: names on controls and images, one `h1`, sensible heading order, labelled fields.
5. Provoke states: empty, invalid input, slow or failing request, very long text, 200% zoom.
6. Look for horizontal scroll, clipped text, overlapping elements, jumps while loading.

## Score (1-5, with one line of evidence each)
Hierarchy, spacing and alignment, typography, colour and contrast, states, interaction feel, responsive, accessibility, copy.

## Report
- Findings ordered by user impact: what is seen, where (screen size, element, `file:line` if known), why it matters, the specific fix.
- "Measured" and "judgement" are labelled separately. Automated checks do not prove accessibility; say what was not tested.
- Finish with the three changes that would most improve the page.

## Fix loop
Screenshot before, change one theme at a time (spacing, then type, then colour, then states, then motion), screenshot after at the same sizes, and compare.
