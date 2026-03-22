XRPL developer utilities: xrpl.js type workarounds, currency/credential encoding, fee adjustment, TransactionMetadata casting, getBalanceChanges, simulate API, submitAndWait errors, transaction result codes.
- **Keywords:** xrpl.js types, currency encoding, credential type, TransactionMetadata, getBalanceChanges, simulate, submitAndWait, transaction result codes, fee adjustment, dev portal mirror
- **Related:** ~/.claude/learnings/financial/numeric-precision-strategy.md

---

## xrpl.js Type Gaps (through v4.6.0)

Several fields returned by rippled are missing from xrpl.js TypeScript types:

| Response type | Missing field | Workaround |
|---|---|---|
| `AccountOffer` | `DomainID` | Cast: `offer as unknown as Record<string, unknown>` |
| `AccountTxTransaction` | `close_time_iso`, `date`, `hash` | Cast: `entry as unknown as Record<string, unknown>` |

`DomainID` IS typed on `Offer` (ledger entry) and `OfferCreate` (transaction) — just missing from the `account_offers` response model. `date` is available indirectly via `tx_json.date` (Ripple epoch number) through `ResponseOnlyTxInfo`, but `close_time_iso` (ISO 8601 string) isn't modeled anywhere on `AccountTxTransaction`.

## Currency Code Encoding Rules

XRPL currency codes follow two encoding rules:
- **Standard (3-char):** Passed through as-is — `"USD"` stays `"USD"`
- **Non-standard (>3 chars):** Hex-encoded and zero-padded to 40 chars — `"RLUSD"` becomes `"524C555344000000..."`

When writing tests that mock XRPL responses containing currency codes, use the **encoded** form that matches what the code under test produces.

## Define Typed Interfaces for XRPL Response Shapes

XRPL `account_tx` entries and similar responses arrive as loosely-typed objects. Rather than casting through `as Record<string, unknown>` at every access, define a local interface once and cast at the entry point:

```ts
interface AccountTxEntry {
  tx_json?: { TransactionType: string; Account: string; Fee?: string; hash?: string };
  meta?: TransactionMetadata | string;
  close_time_iso?: string;
}

const entry = rawEntry as AccountTxEntry;  // One cast at the boundary
```

Eliminates scattered inline casts and gives IDE autocomplete.

## Extract Fee Adjustment as a Pure Helper

XRPL balance changes include the transaction fee for the submitting account's XRP balance. When computing fill amounts, the fee must be subtracted — but only for XRP on the submitter's account. Extract as a pure function to avoid duplication:

```ts
function adjustForFee(value: number, currency: string, account: string, submitter: string, feeDrops: string): number {
  if (currency === "XRP" && account === submitter) {
    return value - parseFloat(feeDrops) / 1_000_000;
  }
  return value;
}
```

## TransactionMetadata Double Cast

xrpl.js `TransactionMetadataBase` types don't expose `AffectedNodes` with enough detail to extract created ledger objects. Direct casting fails because `Node` types lack string index signatures. Fix with double cast through `unknown`:

```ts
const nodes = (meta as unknown as {
  AffectedNodes: Array<Record<string, unknown>>;
}).AffectedNodes;

const created = nodes.find(
  (n) => "CreatedNode" in n &&
    (n.CreatedNode as Record<string, unknown>).LedgerEntryType === "PermissionedDomain",
);
```

## Credential Type Encoding != Currency Encoding

| | Credential Type | Currency Code |
|---|---|---|
| Encoding | Raw UTF-8 → hex | Padded to exactly 40 hex chars |
| Max length | 64 bytes | 20 bytes |
| Helper | `encodeCredentialType()` | `encodeXrplCurrency()` |

Using the wrong encoder produces valid-looking hex that silently fails on the ledger. Keep in separate utility files.

## `getBalanceChanges()` Built-in Utility

xrpl.js provides `getBalanceChanges(metadata)` that handles all AffectedNodes parsing, RippleState sign conventions, and BigNumber arithmetic. Returns per-account balance deltas. Use this instead of manual AffectedNodes iteration — it covers AccountRoot (XRP) and RippleState (tokens) uniformly.

## mduo13.github.io XRPL Dev Portal Mirror

`mduo13.github.io/xrpl-dev-portal/` is a server-rendered mirror of xrpl.org docs. Useful for WebFetch in automated research — the main xrpl.org site is client-rendered (returns empty shells). Confirmed working for pages like `rippling.html`, `ripplestate.html`.

## `simulate` API (rippled 2.4.0+, XLS-69)

Dry-run transaction validation without committing fees or sequence numbers. Submit a transaction with `simulate: true` to get the full result (including metadata) without ledger changes. Requires rippled 2.4.0+; not all public nodes support it. Useful for pre-flight validation of cross-currency payments (verify paths, check delivered_amount).

## xrpl.js `submitAndWait` Error Behavior

`submitAndWait` returns normally for `tec` codes (result available in response). Throws for `tef`, `ter`, `tem` codes. This means:
- `tec` → check `result.meta.TransactionResult`
- `tef`/`ter`/`tem` → catch the thrown error

## Transaction Result Code Fee Behavior

| Code prefix | Fee consumed? | Sequence consumed? | On-ledger? |
|---|---|---|---|
| `tes` | Yes | Yes | Yes |
| `tec` | Yes | Yes | Yes (failed) |
| `tef` | No | No | No |
| `ter` | No | No | No |
| `tem` | No | No | No |
| `tel` | No | No | No |

Critical for retry logic: after `tec`, increment sequence; after `tef`/`ter`/`tem`/`tel`, reuse the same sequence number.
