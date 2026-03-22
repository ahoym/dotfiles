CSS tooltip patterns, SVG gotchas, and centralized design token strategies for Tailwind-based UIs.
- **Keywords:** Tailwind, group-hover, tooltip, SVG title, design tokens, cardClass, inputClass, CSS-in-JS
- **Related:** react-patterns.md, nextjs.md, accessibility-patterns.md

---

## Instant CSS tooltip (Tailwind group-hover)

The native HTML `title` attribute has a browser-imposed ~500ms delay before showing the tooltip. This delay cannot be overridden.

For instant tooltips, use the Tailwind `group/name` + `group-hover/name:block` pattern:

```html
<span class="group/tip relative flex items-center">
  <!-- Trigger element (e.g. icon) -->
  <svg class="h-3.5 w-3.5 cursor-help">...</svg>
  <!-- Tooltip -->
  <span class="pointer-events-none absolute bottom-full right-0 mb-1.5 hidden whitespace-nowrap rounded bg-zinc-900 px-2 py-1 text-xs text-white shadow-lg group-hover/tip:block dark:bg-zinc-700">
    Tooltip text here
  </span>
</span>
```

Key classes:
- `group/tip` on the wrapper creates a named group scope
- `hidden group-hover/tip:block` shows the tooltip on hover with zero delay
- `pointer-events-none` prevents the tooltip from interfering with hover state
- `absolute bottom-full right-0 mb-1.5` positions it above and right-aligned

## SVG `title` is a child element, not an attribute

In SVG, `<title>` is a child element — not an HTML attribute. Using `title={...}` as a JSX prop on `<svg>` causes build failures in Next.js.

**Wrong:**
```jsx
<svg title="My tooltip">...</svg>  // Build error
```

**Right — wrap in parent:**
```jsx
<span title="My tooltip">
  <svg>...</svg>
</span>
```

**Better — use CSS tooltip for instant display** (see pattern above).

## Centralize Design Tokens Before Component-Level Changes

When doing comprehensive UI upgrades across many components, centralize design tokens (colors, spacing, borders, shadows, typography) into shared constants **before** touching individual component files.

**Why:** This enables global design changes (like removing all rounded corners) with a single constant edit instead of touching every component file.

**Pattern:** Define shared Tailwind class constants in a central file (e.g., `lib/ui/ui.ts`):
- `cardClass` — Card wrapper styling (border, background, padding, shadow)
- `inputClass` — Text input styling
- `primaryButtonClass` — Primary action button
- `secondaryButtonClass` — Secondary/outline button
- `dangerButtonClass` — Destructive action button
- `labelClass` — Form field labels

All components import from this file. Changing a constant propagates everywhere instantly.

**Incremental experimentation:** When testing a design change on one page before going app-wide, use Tailwind's `!important` modifier to temporarily override the shared constant (e.g., `className={`${cardClass} !rounded-none`}`). Once the change is confirmed, update the shared constant itself and remove the overrides.

## Cross-Refs

- `react-patterns.md` — component patterns, hooks, and Tailwind usage context
- `nextjs.md` — Next.js build context (SVG title pattern relates to JSX compilation)
- `accessibility-patterns.md` — interaction patterns that complement UI styling
