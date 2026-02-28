# XRPL Patterns

## `getOrderbook()` vs raw `book_offers`

`client.getOrderbook()` (xrpl.js v4.5.0) does significantly more than two `book_offers` calls:
- **Paginates** via `requestAll()` — loops through marker-based pagination to fetch all offers
- **Sorts** both sides by `quality` (exchange rate) using BigNumber — best prices first
- **Limits per-side** after sorting — so `limit=50` returns the 50 best-priced on each side

Raw `book_offers` returns one page in ledger order (not price-sorted). Always prefer `getOrderbook()` unless you need params it doesn't support (e.g., `domain` for permissioned DEX).

## Route-scoped singleton client

When a single route needs a different network than the shared `getClient()` singleton, scope the client to the route file with module-level state. This avoids the shared singleton disconnecting other networks (e.g., a mainnet request would disconnect the active testnet client in `getClient()`).

Pattern: module-level `let client: Client | null`, with connect/reconnect logic mirroring the shared singleton.

## XRPL mainnet WebSocket endpoint

`wss://xrplcluster.com` — public mainnet WebSocket endpoint (cluster of full-history nodes).

## Orderbook: always fetch full book, compute depth server-side

Always fetch `MAX_API_LIMIT` (400) offers per side internally, regardless of display pagination. Compute depth summary (`aggregateDepth()`) server-side from the full book and return it in the response. This ensures depth reflects complete liquidity — display-level slicing (10/25/50/100) happens client-side without affecting the summary.

Pattern used in both `xrpl-dex-portal` and `xrpl-issued-currencies-manager`.

## DepthSummary: use string for volumes

`DepthSummary.bidVolume` / `askVolume` must be `string` (BigNumber `.toFixed()`), not `number`. Aggregating hundreds of offers can produce values that lose precision as float64. The frontend can `parseFloat()` for display formatting where exact precision isn't needed.
