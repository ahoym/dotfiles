# XRPL DEX Data — External APIs

## OnTheDEX Token Data API

Free, no-auth API for XRPL DEX historical and real-time data.

- **Base URL**: `https://api.onthedex.live/public/v1`
- **WebSocket**: `wss://api.onthedex.live/public/v1`
- **Rate limits**: Fair-use; contact `info@onthedex.live` for higher access
- **GitHub**: https://github.com/OnTheDEX/xrpledger-token-data-api

### Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/ohlc` | GET | OHLC candlestick data (up to 5000 bars) |
| `/ticker/:pair` | GET, WS | 24h trading summary |
| `/daily/tokens` | GET | Top 100 traded tokens |
| `/daily/pairs` | GET | Top traded pairs by volume/trades |
| `/aggregator` | GET, POST | Complete 24h token metrics |
| `/token/meta/:tokens` | GET, POST | Token metadata (name, logo) |

### Pair Format

- **Ticker**: `TOKEN.ISSUER:TOKEN.ISSUER` in URL path
- **OHLC**: `base=TOKEN.ISSUER&quote=TOKEN.ISSUER` as query params
- Multiple pairs: concatenate with `+`

### OHLC Parameters

- `base`, `quote` — `CURRENCY.ISSUER` format (XRP has no issuer)
- `interval` — timeframe in minutes (e.g., `60` = 1h)
- `bars` — number of candles (max 5000)

### OHLC Response Shape

```json
{
  "spec": { "base": {...}, "quote": {...}, "interval": "60", "bars": 5 },
  "data": {
    "marker": "...",
    "ohlc": [
      { "t": 1772157600, "o": 0.1949, "h": 0.1949, "l": 0.1942, "c": 0.1949, "vb": 57592.7, "vq": 11213.1 }
    ]
  }
}
```

Fields: `t` (unix timestamp), `o/h/l/c` (prices), `vb` (base volume), `vq` (quote volume).

### Ticker Response Shape

```json
{
  "pairs": [{
    "base": {...}, "quote": {...},
    "last": 0.19492, "ago24": 0.19526, "pc24": -0.17,
    "price_hi": 0.19532, "price_lo": 0.19380, "price_mid": 0.1949,
    "num_trades": 6699, "volume_base": 1224024, "volume_quote": 238319, "volume_usd": 238240,
    "trend": "up", "time": 1772175011
  }]
}
```

## XRPL Native DEX — Protocol Reference

The XRP Ledger has a built-in DEX since 2012 using a **Central Limit Order Book (CLOB)**, with hybrid CLOB + AMM routing available. Trades execute when ledgers close (every 3-5 seconds). Transaction execution order is intentionally unpredictable to discourage front-running. No native market orders, stop orders, or leverage.

### Offers (Limit Orders)

An **Offer** is a limit order created via `OfferCreate`. Key fields: `TakerPays` (what creator wants to receive), `TakerGets` (what creator will give up), optional `Expiration` and `OfferSequence`.

**OfferCreate flags:**

| Flag | Hex | Effect |
|---|---|---|
| `tfPassive` | 0x00010000 | Don't consume at exact same rate |
| `tfImmediateOrCancel` | 0x00020000 | Execute what's possible, never rest |
| `tfFillOrKill` | 0x00040000 | Cancel if can't fill entirely |
| `tfSell` | 0x00080000 | Spend entire TakerGets even if receiving more than TakerPays |

**Funding rules:** Placing an offer does NOT lock up funds — you can place multiple offers against the same balance. Unfunded offers stay in the ledger until a transaction encounters and removes them (lazy cleanup).

**Trust lines and offers:** Offers can exceed trust line limits (explicit trade intent overrides). Executing an offer auto-creates a trust line (with limit 0) if needed.

### Auto-Bridging

Any token-to-token trade can automatically use **XRP as an intermediary** when it produces a better rate. Creates a synthetic order book by composing two order books. Happens at the protocol level — no trader action required.

### Tick Size

Issuers can set `TickSize` (3-15, or 0 to disable) via `AccountSet`. Truncates exchange rates to that many significant digits. Does not affect the immediately-executed portion. `tfImmediateOrCancel` offers are unaffected.

### Cross-Currency Payments

`Payment` transactions can consume DEX offers to convert currencies. The protocol finds payment paths through intermediary accounts and order books. Payments can use multiple paths simultaneously. Auto-bridging through XRP also applies.
