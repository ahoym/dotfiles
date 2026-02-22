# Accessibility Attribute Patterns

Quick reference for common accessibility gaps in React/Next.js components and their fixes.

## Navigation links

```tsx
// Active page indication for screen readers
<Link href={link.href} aria-current={active ? "page" : undefined}>
```

## Collapsible sections

```tsx
// Communicate expanded/collapsed state
<button
  onClick={() => setCollapsed((v) => !v)}
  aria-expanded={!collapsed}
>
```

## Toggle buttons (tab-like selectors)

```tsx
// Communicate which option is selected
<button
  onClick={() => setMode("option1")}
  aria-pressed={mode === "option1"}
>
```

## Show/hide toggle buttons

```tsx
// Describe the action, not the label text
<button
  type="button"  // prevent form submission
  onClick={() => setShow(!show)}
  aria-label={show ? "Hide secret" : "Show secret"}
>
```

## Clickable non-button elements (spans, divs)

When a `<span>` or `<div>` has an `onClick` handler, add keyboard support:

```tsx
<span
  onClick={handleClick}
  role="button"
  tabIndex={0}
  onKeyDown={(e: React.KeyboardEvent) => {
    if (e.key === "Enter" || e.key === " ") handleClick();
  }}
>
```

All three attributes (`role`, `tabIndex`, `onKeyDown`) are needed together. Only add them when the element is actually interactive (conditionally, if the click handler is conditional).

## Common audit checklist

| Element | Check |
|---------|-------|
| Nav links | `aria-current="page"` on active link |
| Collapsible panels | `aria-expanded` on trigger button |
| Toggle button groups | `aria-pressed` on each button |
| Icon-only buttons | `aria-label` describing the action |
| Non-button clickables | `role="button"` + `tabIndex={0}` + `onKeyDown` |
| Form buttons that don't submit | `type="button"` to prevent default submit |
