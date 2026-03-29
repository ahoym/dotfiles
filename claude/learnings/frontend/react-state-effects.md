React 19 state management — setState restrictions in useEffect, lazy initializers, render-time sync, hydration mismatch prevention, and per-environment localStorage.
- **Keywords:** React 19, useState, useEffect, lazy initializer, render-time sync, hydration mismatch, localStorage, per-environment state, fetchKey
- **Related:** none

---

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

## Per-Environment Frontend State with Migration

When an app supports multiple environments (testnet/devnet, staging/production), store client-side state as separate keys per environment:

```ts
// Separate keys prevent cross-environment contamination
localStorage.getItem("app-state-testnet")
localStorage.getItem("app-state-devnet")
```

When migrating from a legacy single-key format, perform a one-time migration on app initialization:
1. Check if legacy key exists
2. Read and parse legacy data
3. Write to new per-environment key
4. Delete legacy key

This pattern is transparent to users and prevents data loss during schema evolution.
