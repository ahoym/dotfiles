# XRPL Testing Patterns

## Crossing offers for trade/fill test data

To test endpoints that require actual trade data (`filled-orders`, `dex/trades`), you need crossing offers — two accounts placing opposite offers that match and execute:

1. Issuer (with `isIssuer:true` for DefaultRipple) + Trader A + Trader B
2. Trust lines: both traders -> issuer for the currency
3. Issue currency to Trader A (the seller)
4. Trader A places sell offer: `TakerGets=100 USD, TakerPays=50 XRP`
5. Trader B places crossing buy offer: `TakerGets=50 XRP, TakerPays=100 USD`

Step 5 auto-executes against step 4's resting offer, producing a fill visible to both `filled-orders` (per-account) and `dex/trades` (per-pair) endpoints.

Key: Trader B needs XRP (from faucet) but only needs a trust line (not a balance) for USD, since `TakerPays` only requires a trust line.
