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
