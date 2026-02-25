# React Patterns

## React 19: No setState in useEffect

React 19's lint rules prohibit calling `setState` synchronously inside `useEffect` ("Calling setState synchronously within an effect can trigger cascading renders"). Two alternatives:

### 1. Lazy `useState` initializer (for hydration/init)
Instead of setting state in a mount effect, compute the initial value in the `useState` callback:

```tsx
// BAD — React 19 lint error
const [value, setValue] = useState<string | null>(null);
useEffect(() => {
  setValue(localStorage.getItem("key"));
}, []);

// GOOD — lazy initializer
const [value, setValue] = useState<string | null>(() => {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("key");
});
```

### 2. Render-time state sync (for prop sync)
Instead of syncing state to props in `useEffect`, store the previous prop value and compare during render:

```tsx
// BAD — React 19 lint error
useEffect(() => {
  setInputValue(propValue ?? "");
}, [propValue]);

// GOOD — render-time sync
const [prevPropValue, setPrevPropValue] = useState(propValue);
if (prevPropValue !== propValue) {
  setPrevPropValue(propValue);
  setInputValue(propValue ?? "");
}
```

This is the pattern recommended by the React docs ("Adjusting state when a prop changes").

### 3. Data-fetching effects with loading/error state

For effects that fetch data and set loading/error state, derive a `fetchKey` and use render-time sync for the "starting fetch" state transitions. The effect body only contains async callbacks (which are allowed):

```tsx
// Derive a key that changes when we need a new fetch
const fetchKey = url ? `${url}::${refreshKey}` : null;

// Synchronously set loading=true when fetchKey changes (render-time pattern)
const [prevFetchKey, setPrevFetchKey] = useState(fetchKey);
if (prevFetchKey !== fetchKey) {
  setPrevFetchKey(fetchKey);
  if (!fetchKey) {
    setData(null);
    setLoading(false);
  } else {
    setLoading(true);
    setError(null);
  }
}

// Effect only does the async work — setState calls are in callbacks (allowed)
useEffect(() => {
  if (!url) return;
  let cancelled = false;
  fetch(url)
    .then((res) => res.json())
    .then((data) => { if (!cancelled) setData(data); })
    .finally(() => { if (!cancelled) setLoading(false); });
  return () => { cancelled = true; };
}, [url, refreshKey]);
```

**Key insight:** `setLoading(true)` at the top of an effect body is synchronous and triggers the lint error. Moving it to render-time via the prev-key pattern is the correct fix.

## Hydration Mismatch with localStorage-Derived Values

Components that render values from `localStorage` (e.g., network selector, theme toggle) will cause hydration mismatches in SSR frameworks because the server renders a default value while the client reads from storage.

**Fix:** Gate rendering on a `hydrated` flag that starts `false` on the server and becomes `true` on the client.

```tsx
const { state, hydrated } = useAppState();

// Only render after hydration to avoid mismatch
{hydrated && <NetworkSelector network={state.network} />}
```

**Why not `suppressHydrationWarning`?** That only suppresses the warning — the user still sees a flash of the wrong value. Gating avoids rendering the wrong value entirely.

## Circular Dependency When Extracting Hooks

When extracting a custom hook that both **produces** derived state and **consumes** that derived state for further computation, pass primitive values (strings, numbers) into the hook rather than resolved objects.

**The Problem:** A hook builds `currencyOptions` from balances and needs `sellingCurrency` (an object resolved from `currencyOptions`) to fetch orderbook data. If the caller must pass `sellingCurrency` as a prop, it needs `currencyOptions` from the hook to resolve it — creating a circular dependency.

**The Solution:** Accept string identifiers and resolve internally:

```typescript
// BAD: Circular — caller needs currencyOptions to compute sellingCurrency
function useTradingData({ sellingCurrency }: { sellingCurrency: CurrencyOption | null }) {
  const currencyOptions = useMemo(() => /* build from balances */);
}

// GOOD: Accept primitives, resolve internally
function useTradingData({ sellingValue }: { sellingValue: string }) {
  const currencyOptions = useMemo(() => /* build from balances */);
  const sellingCurrency = useMemo(
    () => currencyOptions.find((o) => o.value === sellingValue) ?? null,
    [currencyOptions, sellingValue],
  );
  return { currencyOptions, sellingCurrency, /* ... */ };
}
```

**When this applies:** Extracting data-fetching hooks that also build option lists, or any hook that derives state and then uses that derived state for side effects (fetches, subscriptions).

## Lift Execution State to Parent for Non-Blocking UI

When a modal triggers a long-running async operation (e.g., placing multiple orders sequentially), lift the execution state (`progress`, `results`) to the parent component. This lets the modal close immediately after confirmation while the parent continues running the operation and reflects progress in its own UI.

## Modal as Form-Only with Parent-Owned Execution

Design modals to handle only form input and preview, then call an `onExecute(data)` callback instead of running async operations internally. The parent owns the execution loop and state. Pattern: Modal exposes `onExecute` prop (not `onComplete`). Parent closes modal on execute and runs work independently.

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
