React hook extraction patterns and UI component lifecycle — circular dependency avoidance, two-tier hook design, modal lifecycle, polling with visibility gating, and page decomposition.
- **Keywords:** hooks, circular dependency, two-tier design, modal, refreshKey, polling, Page Visibility API, component decomposition, sub-components
- **Related:** ~/.claude/learnings/reactive-data-patterns.md, ~/.claude/learnings/refactoring-patterns.md

---

## Circular Dependency When Extracting Hooks

When extracting a custom hook that both **produces** derived state and **consumes** that derived state for further computation, pass primitive values (strings, numbers) into the hook rather than resolved objects.

**The Problem:** A hook builds `options` from raw data and needs `selectedItem` (an object resolved from `options`) to fetch related data. If the caller must pass `selectedItem` as a prop, it needs `options` from the hook to resolve it — creating a circular dependency.

**The Solution:** Accept string identifiers and resolve internally:

```typescript
// BAD: Circular — caller needs options to compute selectedItem
function useComboData({ selectedItem }: { selectedItem: SelectOption | null }) {
  const options = useMemo(() => /* build from raw data */);
}

// GOOD: Accept primitives, resolve internally
function useComboData({ selectedValue }: { selectedValue: string }) {
  const options = useMemo(() => /* build from raw data */);
  const selectedItem = useMemo(
    () => options.find((o) => o.value === selectedValue) ?? null,
    [options, selectedValue],
  );
  return { options, selectedItem, /* ... */ };
}
```

**When this applies:** Extracting data-fetching hooks that also build option lists, or any hook that derives state and then uses that derived state for side effects (fetches, subscriptions).

## Don't Unmount Modals Immediately After Success

When a modal calls `onClose()` immediately after a successful API call, the component unmounts before the success message renders — making the confirmation invisible to both users and Playwright tests.

```tsx
// BAD — modal unmounts before success banner is visible
if (result) {
  onSuccess();
  onClose(); // unmounts component, success state destroyed
}

// GOOD — delay close so user sees confirmation
if (result) {
  onSuccess();
  setTimeout(() => onClose(), 1000);
}
```

**Why it happens:** `useFormSubmit` sets `success = true` and schedules a 2s auto-clear timer. But `onClose()` fires synchronously after `setSuccess(true)`, causing the parent to set `showModal = false`, unmounting the modal before React re-renders with the success banner. The auto-clear timer is cleaned up by the unmount effect and never fires.

**Symptoms:** E2E tests time out waiting for success text; screenshots show the page with no modal open and no error visible. Users see a flash (or nothing) before the modal disappears.

## Modal Execution Ownership

Design modals to handle only form input and preview, then call an `onExecute(data)` callback — not `onComplete`. The parent owns the execution loop: it closes the modal immediately on execute, runs the async operation (e.g., sequential API calls), and reflects progress in its own UI. Lifting execution state (`progress`, `results`) to the parent means the modal doesn't block while work continues.

## Per-Iteration refreshKey Bump for Live Updates

In sequential async loops, bump `refreshKey` after each successful iteration rather than only at the end. This triggers data re-fetching hooks after every operation so the user sees results in real time. Works because `await` between iterations yields control back to React.

## Large Pages: Decompose into Sub-Components with Shared Hooks

When a page component grows beyond ~200 lines, decompose it into:

1. **Slim orchestrator page** (~100-150 lines) — owns top-level state, wires props between sections
2. **Sub-components** in a dedicated subdirectory (e.g., `app/components/feature/`) — each manages its own submission/loading/error state
3. **Shared hooks** in `lib/hooks/` — extract repeated data-fetching and action patterns

**Rules:**
- Each sub-component owns its action state (loading, error for its own POST calls) — the orchestrator doesn't need to know about submission details
- Shared hooks own fetch state (data, loading, refresh) — multiple components consume the same hook independently
- The orchestrator provides context (addresses, config, callbacks for cross-component refresh)
- **Refresh coordination:** Pass `refreshKey` numbers or `onChanged` callbacks to trigger sibling refreshes when one component modifies shared data

**When NOT to extract:**
- Don't extract a hook for a one-off action unique to a single component
- Don't extract a sub-component for a section < 50 lines
- Don't extract a shared hook if only one consumer exists (extract when a second consumer appears)

## Audit Before Abstracting: Two-Tier Hook Design

When extracting a "repeated pattern" across N components into a shared abstraction, research every component's actual usage first. The pattern is often less uniform than it appears.

**Approach:**
1. Read each component's implementation — don't just grep for the pattern
2. Catalog the variations: loading state type (boolean vs string key vs enum), success state shape, argument passing
3. Group components by actual compatibility, not surface similarity
4. Design tiered abstractions covering the real groups — don't force outliers

**Key insight:** Two focused tiers covering 6 of 8 components is better than one over-generalized abstraction that awkwardly handles all 8.

## Polling with Page Visibility Gating

Silent polling (e.g., every 3 seconds) should be gated on the Page Visibility API to prevent background tabs from wasting bandwidth and server resources:

```ts
function usePageVisible(): boolean {
  const [visible, setVisible] = useState(true);
  useEffect(() => {
    const handler = () => setVisible(document.visibilityState === "visible");
    document.addEventListener("visibilitychange", handler);
    return () => document.removeEventListener("visibilitychange", handler);
  }, []);
  return visible;
}

function usePollInterval(callback: () => void, intervalMs: number) {
  const isVisible = usePageVisible();
  useEffect(() => {
    if (!isVisible) return;
    const id = setInterval(callback, intervalMs);
    return () => clearInterval(id);
  }, [isVisible, callback, intervalMs]);
}
```

Prevents background tabs from hammering the server and avoids stale data issues when the tab becomes visible again (the interval restarts cleanly).

## Cross-Refs

- `~/.claude/learnings/reactive-data-patterns.md` — refresh, polling, localStorage sync
- `~/.claude/learnings/refactoring-patterns.md` — survey methodology for component refactors
