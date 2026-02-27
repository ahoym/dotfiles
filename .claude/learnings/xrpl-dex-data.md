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
