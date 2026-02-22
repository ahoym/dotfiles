# React Patterns

## Error Boundary Isolation for Feature Sections

When adding a new feature section to an existing page (e.g., "Credentials" section on a setup page that already has "Trust Lines"), wrap the new section in an `ErrorBoundary` with a graceful fallback.

**Why:** A malformed data shape from an API (e.g., unexpected credential object) can crash the entire page if the new component throws during render. An error boundary contains the blast radius to just the new section.

**Pattern:**
```tsx
<ErrorBoundary fallback={<div className={cardClass}><p className={errorTextClass}>Failed to load credentials section.</p></div>}>
  <CredentialManagement ... />
</ErrorBoundary>
```

**When to use:** Any time a new data-fetching UI section is added to a page that already has other working sections. Especially important when the data source is external/untrusted (e.g., on-ledger data that could have unexpected shapes).

**Note:** The `useApiFetch` hook's error state handles fetch failures — the error boundary catches render-time crashes from bad data shapes that pass the fetch but break JSX rendering.

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

## Audit Before Abstracting: Two-Tier Hook Design

When extracting a "repeated pattern" across N components into a shared abstraction, research every component's actual usage first. The pattern is often less uniform than it appears.

**Approach:**
1. Read each component's implementation — don't just grep for the pattern
2. Catalog the variations: loading state type (boolean vs string key vs enum), success state shape, argument passing
3. Group components by actual compatibility, not surface similarity
4. Design tiered abstractions covering the real groups — don't force outliers

**Key insight:** Two focused tiers covering 6 of 8 components is better than one over-generalized abstraction that awkwardly handles all 8.
