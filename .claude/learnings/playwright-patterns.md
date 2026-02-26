# Playwright E2E Testing Patterns

Patterns, gotchas, and best practices for writing Playwright end-to-end tests.

## 1. Shared BrowserContext for Serial Tests

When using `test.describe.serial()` in Playwright, each test gets its own `BrowserContext` by default (via the `{ page }` fixture). This means **localStorage is NOT shared** between serial tests. To share state (e.g., session data stored in localStorage), create a shared `BrowserContext` and `Page` in `beforeAll`, and have test callbacks use `async ()` (no fixture destructuring) so they reference the closure variables.

```ts
test.describe.serial("Feature", () => {
  let context: BrowserContext;
  let page: Page;

  test.beforeAll(async ({ browser }) => {
    context = await browser.newContext({ storageState: ".auth/state.json" });
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

## 4. Nav Bar textContent Concatenation Causes False Regex Matches

`textContent` on container elements concatenates all child text **without separators**. A nav bar with links "Home", "Settings", "Profile", "Logout" produces the string:

```
HomeSettingsProfileLogout
```

This concatenated string can false-match regexes intended for other content (e.g., an identifier pattern like `/[a-zA-Z0-9]{8,}/`), causing **strict mode violations** when using `getByText()` with regex locators.

**Fix:** Use role-based selectors that target specific elements rather than searching all text content:

```ts
// Bad — matches concatenated nav text
await page.getByText(/[a-zA-Z0-9]{8,}/).click();

// Good — targets a specific link element
await page.getByRole("link", { name: /^[a-zA-Z0-9]{8,}/ }).click();
```

## 5. Scope Selectors to Containers to Avoid Strict Mode Violations

When a page has duplicate interactive elements (e.g., a dropdown in the nav bar AND another dropdown in a modal), unscoped selectors like `page.getByRole("combobox").first()` may resolve to the wrong element or cause strict mode errors if multiple matches exist.

**Fix:** Scope selectors to a parent container using `.locator()`:

```ts
// Bad — may match nav bar combobox instead of modal combobox
await page.getByRole("combobox").first().click();

// Good — scoped to the form/modal container
const modal = page.locator("form");
await modal.getByRole("combobox").first().click();
```

This is common when a page has multiple interactive elements across different containers (e.g., a dropdown in the nav bar and another in a modal).

## 6. StorageState for localStorage-Only Apps (No Cookies/Sessions)

Playwright's `storageState` is typically used for authentication cookies, but it also captures `localStorage` via the `origins[].localStorage` structure. For apps where all state lives in `localStorage` (no auth cookies, no server sessions), the global setup can bootstrap state through the UI and save it:

```ts
// global-setup.ts — save state after bootstrapping
await page.context().storageState({ path: ".auth/state.json" });
```

Downstream specs restore this state automatically via config:
```ts
// playwright.config.ts
{ name: "my-spec", use: { storageState: ".auth/state.json" }, dependencies: ["setup"] }
```

The saved JSON structure — `origins[].localStorage` holds key-value pairs, `cookies` is empty for localStorage-only apps:
```json
{
  "origins": [{
    "origin": "http://localhost:3000",
    "localStorage": [{ "name": "app-session", "value": "{\"user\":{...}}" }]
  }],
  "cookies": []
}
```

**Key insight:** Components that gate rendering on a `hydrated` flag (from `useLocalStorage`) will show loading states until the first client-side render hydrates from `localStorage`. Downstream specs should wait for hydration (e.g., assert an address link is visible) before interacting with the page.

## 7. `selectOption` Only Accepts `string` for `label` — Not `RegExp`

Playwright's `selectOption()` method types the `label` field as `string`, not `string | RegExp`. This is different from most Playwright locator methods (`getByRole`, `getByText`, `getByLabel`) which accept both `string` and `RegExp`.

```ts
// Fails TypeScript compilation — label must be string
await page.locator("select").selectOption({ label: /USD/ });

// Works — exact string match
await page.locator("select").selectOption({ label: "USD" });
```

**When the label isn't known exactly** (e.g., it includes dynamic content like balances), find the option element by text and extract its value:

```ts
const option = page.locator("option").filter({ hasText: "USD" });
const value = await option.getAttribute("value");
await page.locator("select").selectOption(value!);
```

**Note:** `<select>` option values are implementation-specific. Some apps use the display text, others use indices (`"0"`, `"1"`), and others use encoded compound keys (e.g., `"id|category"`). Always inspect the actual DOM to determine the value format.

## 8. Use `exact: true` for Ambiguous Button Names

`getByRole("button", { name: "Add" })` can match multiple elements when the page has a `<span role="button">` whose accessible name contains "Add" (e.g., "Copy address" where the parent text includes "Add"). This causes Playwright strict mode violations in CI even if it works locally (due to timing differences).

```ts
// Bad — matches both <span role="button" title="Copy address"> and <button>Add</button>
// when the accessible name computation includes "Add" from surrounding text
await page.getByRole("button", { name: "Add" }).click();

// Good — exact match prevents partial/substring matches
await page.getByRole("button", { name: "Add", exact: true }).click();
```

**When to use:** Always use `exact: true` for short, common button names ("Add", "OK", "Go", "Set") that could appear as substrings in other elements' accessible names.

## 9. Option Visibility in `<select>`

`<option>` elements inside a collapsed `<select>` are attached to the DOM but NOT considered "visible" by Playwright. Use `waitFor({ state: "attached" })` instead of default `waitFor()` (which waits for "visible").

## 10. `getByLabel()` Requires Proper HTML Association

`getByLabel("Base")` only works when the `<label>` is associated with the control via `for`/`id` or by wrapping. A sibling `<label>` without `for` renders as `generic` in the aria tree — Playwright won't find the associated `<select>`. Fix: add `htmlFor`/`id` attributes.

## 11. Modal Scoping with `role="dialog"`

When modals overlay the main page, `getByRole("spinbutton")` or `getByPlaceholder()` can match elements in BOTH the modal and the page. Fix: add `role="dialog"` and `aria-modal="true"` to the modal container, then scope all modal interactions with `page.getByRole("dialog")`.

## 12. Strict Mode and `getByText()` Substring Matching

`getByText("Foo")` does case-insensitive substring matching — "Foo" matches "Foobar", "Copy Foo address", etc. When multiple elements match, Playwright throws a strict mode violation. Fixes: `{ exact: true }`, or use `getByRole` with a specific role (e.g., `getByRole("cell", { name: "KYC" })`).

## 13. `.first()` Is a Dynamic Locator

After removing the first matched element (e.g., cancelling an order), `.first()` resolves to the NEXT element. `expect(btn).not.toBeVisible()` will fail because the new first is still visible. Fix: use count-based assertions — `expect(locator).toHaveCount(initialCount - 1)`.

## 14. Dynamic File Inputs — Use `filechooser` Event

When app creates `<input type="file">` dynamically via JS (not pre-existing in DOM), `locator('input[type="file"]').setInputFiles()` finds nothing. Use:
```typescript
const [fileChooser] = await Promise.all([
  page.waitForEvent("filechooser"),
  page.getByRole("button", { name: "Import" }).click(),
]);
await fileChooser.setFiles(filePath);
```

## 15. Transient Success Banners Are Unreliable Assertions

Success messages that auto-clear after 2s can be missed by Playwright assertions even with long timeouts. Assert the **side effect** instead (e.g., item appears in a list, form resets, button state changes).

## 16. `.filter({ has: getByText() }).first()` Matches Ancestor Divs

`page.locator("div").filter({ has: getByText("Card Title") }).first()` can match a high-level ancestor div containing multiple cards. For tighter scoping, use the heading's parent: `page.getByRole("heading", { name: "Card Title" }).locator("..")`.

## 17. `.or()` for One-of-Many Terminal States

When external state is unpredictable (e.g., testnet AMM pool may or may not exist), use `.or()` to assert that one of several valid outcomes is visible rather than branching with try/catch or conditional logic:

```ts
const poolData = page.getByText("Spot Price");
const noPool = page.getByText("No AMM pool exists for this pair");
const emptyPool = page.getByText("Pool is empty");

await expect(poolData.or(noPool).or(emptyPool)).toBeVisible({ timeout: 15_000 });
```

This is cleaner than try/catch + `test.skip()` when all outcomes are valid — the test passes regardless of which state is reached, but still fails if the component is stuck loading or errors out.
