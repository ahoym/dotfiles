# Playwright E2E Testing Patterns

Patterns, gotchas, and best practices for writing Playwright end-to-end tests.

---

## 1. Shared BrowserContext for Serial Tests

When using `test.describe.serial()` in Playwright, each test gets its own `BrowserContext` by default (via the `{ page }` fixture). This means **localStorage is NOT shared** between serial tests. To share state (e.g., a generated wallet stored in localStorage), create a shared `BrowserContext` and `Page` in `beforeAll`, and have test callbacks use `async ()` (no fixture destructuring) so they reference the closure variables.

```ts
test.describe.serial("Feature", () => {
  let context: BrowserContext;
  let page: Page;

  test.beforeAll(async ({ browser }) => {
    context = await browser.newContext({ storageState: ".auth/wallet.json" });
    page = await context.newPage();
  });

  test.afterAll(async () => {
    await context.close();
  });

  test("step 1", async () => {
    /* use closure `page` — localStorage persists */
  });

  test("step 2", async () => {
    /* same page and context, localStorage carries over */
  });
});
```

**Key takeaway:** If you destructure `{ page }` from the test fixture in a serial block, each test gets a fresh context and localStorage is wiped. Use closure variables instead.

---

## 2. page.once vs page.on for Dialog Handlers on Shared Pages

When reusing a `Page` instance across serial tests, using `page.on("dialog", handler)` **stacks handlers** — each test adds another listener. When a dialog fires, multiple handlers try to accept it, causing:

```
Cannot accept dialog which is already handled!
```

**Fix:** Use `page.once("dialog", handler)` for one-time dialog handling. This automatically removes the handler after a single invocation, preventing stacking across tests.

```ts
// Bad — stacks handlers across serial tests
page.on("dialog", (d) => d.accept());

// Good — one-time handler, no stacking
page.once("dialog", (d) => d.accept());
```

---

## 3. getByRole Uses Accessible Name (aria-label) Over Visible Text

Playwright's `getByRole("button", { name: "..." })` matches the **accessible name**, which prioritizes `aria-label` over visible text content. A button with `aria-label="Expand orders"` and inner text "Show Orders" will **NOT** match `{ name: "Show Orders" }`.

```html
<button aria-label="Expand orders">Show Orders</button>
```

```ts
// Fails — "Show Orders" is the visible text, not the accessible name
await page.getByRole("button", { name: "Show Orders" }).click();

// Works — matches the aria-label
await page.getByRole("button", { name: "Expand orders" }).click();
```

**Tip:** Use the Playwright Inspector or `page.getByRole("button").all()` to debug which names Playwright sees for each element.

---

## 4. Nav Bar textContent Concatenation Causes False Regex Matches

`textContent` on container elements concatenates all child text **without separators**. A nav bar with links "Trade", "Transact", "Explorer", "Testnet" produces the string:

```
TradeTransactExplorerTestnet
```

The substring `radeTransactExplorerTestnet` (27 characters starting with "r") matches `/r[a-zA-Z0-9]{24,}/` — a regex intended for XRPL addresses (which start with "r" followed by 24+ alphanumeric chars). This causes **strict mode violations** when using `getByText()` with address-like patterns.

**Fix:** Use role-based selectors that target specific elements rather than searching all text content:

```ts
// Bad — matches concatenated nav text
await page.getByText(/r[a-zA-Z0-9]{24,}/).click();

// Good — targets a specific link element
await page.getByRole("link", { name: /^r[a-zA-Z0-9]{24,}/ }).click();
```

---

## 5. Scope Selectors to Containers to Avoid Strict Mode Violations

When a page has duplicate interactive elements (e.g., a network selector in the nav bar AND a currency selector in a modal), unscoped selectors like `page.getByRole("combobox").first()` may resolve to the wrong element or cause strict mode errors if multiple matches exist.

**Fix:** Scope selectors to a parent container using `.locator()`:

```ts
// Bad — may match nav bar combobox instead of modal combobox
await page.getByRole("combobox").first().click();

// Good — scoped to the form/modal container
const modal = page.locator("form");
await modal.getByRole("combobox").first().click();
```

This is common when a page has multiple interactive elements across different containers (e.g., a dropdown in the nav bar and another in a modal).

---

## 6. StorageState for localStorage-Only Apps (No Cookies/Sessions)

Playwright's `storageState` is typically used for authentication cookies, but it also captures `localStorage` via the `origins[].localStorage` structure. For apps where all state lives in `localStorage` (no auth cookies, no server sessions), the global setup can bootstrap state through the UI and save it:

```ts
// global-setup.ts — save state after bootstrapping
await page.context().storageState({ path: ".auth/wallet.json" });
```

Downstream specs restore this state automatically via config:
```ts
// playwright.config.ts
{ name: "my-spec", use: { storageState: ".auth/wallet.json" }, dependencies: ["setup"] }
```

The saved JSON contains:
```json
{
  "origins": [{
    "origin": "http://localhost:3000",
    "localStorage": [
      { "name": "app-theme", "value": "dark" },
      { "name": "app-session", "value": "{\"user\":{...},\"preferences\":[...]}" }
    ]
  }],
  "cookies": []
}
```

**Key insight:** Components that gate rendering on a `hydrated` flag (from `useLocalStorage`) will show loading states until the first client-side render hydrates from `localStorage`. Downstream specs should wait for hydration (e.g., assert an address link is visible) before interacting with the page.

---

## 7. `selectOption` Only Accepts `string` for `label` — Not `RegExp`

Playwright's `selectOption()` method types the `label` field as `string`, not `string | RegExp`. This is different from most Playwright locator methods (`getByRole`, `getByText`, `getByLabel`) which accept both `string` and `RegExp`.

```ts
// Fails TypeScript compilation — label must be string
await page.locator("select").selectOption({ label: /TCOIN/ });

// Works — exact string match
await page.locator("select").selectOption({ label: "TCOIN" });
```

**When the label isn't known exactly** (e.g., it includes dynamic content like balances), find the option element by text and extract its value:

```ts
const option = page.locator("option").filter({ hasText: "TCOIN" });
const value = await option.getAttribute("value");
await page.locator("select").selectOption(value!);
```

**Note:** `<select>` option values are implementation-specific. Some apps use the display text, others use indices (`"0"`, `"1"`), and others use encoded keys (e.g., `"XRP|"` for currency code + pipe + issuer). Always inspect the actual DOM to determine the value format.
