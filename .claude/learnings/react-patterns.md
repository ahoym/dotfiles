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
