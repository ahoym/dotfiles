# Browser Security Learnings

## URI XSS via `javascript:` Protocol in `<a href>`

When rendering URIs from external or user-controlled sources as clickable `<a href>` links, validate the protocol. A `javascript:alert(document.cookie)` payload executes arbitrary JavaScript when clicked.

**Fix:** Allowlist `http:`/`https:` before rendering as a link. Render everything else as inert text:

```tsx
{uri ? (
  /^https?:\/\//i.test(uri) ? (
    <a href={uri} target="_blank" rel="noopener noreferrer">{uri}</a>
  ) : (
    <span>{uri}</span>
  )
) : "—"}
```

**General rule:** Never pass untrusted strings directly into `href` attributes. Allowlist expected protocols (`http:`, `https:`, optionally `mailto:`) and treat everything else as plain text. This is a **stored XSS vector** when the payload persists in an external data source (database, third-party API, blockchain ledger).
