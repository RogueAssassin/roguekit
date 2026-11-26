# Natural interaction: what makes a page feel right

## Respond immediately
- Every press, tap and hover shows a change within about 100ms (`:active` state, not only `:hover`).
- Under about 1s: no spinner (delay indicators ~300ms to avoid flashes). Longer: skeletons shaped like the content. Very long: progress, and let the user keep working.
- Optimistic updates for low-risk actions, with rollback and a clear message on failure.
- Prefer undo to "Are you sure?"; confirm only irreversible actions, naming the thing affected.

## Motion that explains
- Motion shows where something came from or went; if it explains nothing, remove it.
- Durations: 100-150ms small feedback, 150-250ms menus and popovers, 250-350ms panels and dialogs. Exits are faster than entrances.
- Entering: ease-out. Leaving: ease-in. Moving between positions: ease-in-out. Avoid linear except for continuous progress.
- Animate `transform` and `opacity`; avoid animating width, height, top or left. Never `transition: all`.
- Interruptible: a second click reverses smoothly. Never block input while animating.
- Popovers scale from the trigger (`transform-origin`).

```css
:root { --ease-out: cubic-bezier(.2,.8,.2,1); --dur-fast: 120ms; --dur: 200ms; }
.button { transition: transform var(--dur-fast) var(--ease-out), background-color var(--dur-fast); }
.button:active { transform: scale(.98); }
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: .01ms !important; transition-duration: .01ms !important; scroll-behavior: auto !important; }
}
```
View Transitions and scroll-driven animation are enhancements only: the page must work without them.

## Behave like the platform
- Links navigate, buttons act; Back, middle-click, copy and zoom keep working. No scroll hijacking.
- Keep scroll position and typed input across navigation and errors.
- Dialogs: focus moves in, Escape closes, focus returns to the opener (`<dialog>` helps).
- Keyboard: logical order, visible `:focus-visible`, Enter submits.
- Touch: targets at least 24x24 CSS px (AA), aim for 44x44; nothing available on hover only; correct `inputmode` and `autocomplete`.

## Forms
- Visible labels (placeholders are not labels). One column. Mark optional fields.
- Validate on blur or submit, not on first keystroke; clear the error as soon as it is fixed.
- Error text sits by the field and says how to fix it; move focus to the first error on submit.
- Accept pasted and loosely formatted input; never disable paste.

## Every state
Design and check: first use/empty (explain and offer the next action), loading, partial, error (what happened, what to do, retry), success, offline, no permission, very long text, zero/one/many items.

## Words
- Buttons name the outcome ("Save changes", not "Submit"). Same term for the same thing everywhere.
- Plain, short, specific; no blame; no internal error codes without a human explanation.
