XRPL DEX trade-history forensics: parsing meta to extract executed trades, volumes, and counterparties.
- **Keywords:** account_tx, RippleState, AffectedNodes, Offer, ModifiedNode, DeletedNode, TakerGets, TakerPays, delivered_amount, DEX, BBRL, RLUSD, trade analysis
- **Related:** dex-data.md, patterns.md, wallet-clustering.md

---

## Issuer `account_tx` is the universal trade index

Every trade involving an IOU touches a trust line where the issuer is a party. Paginating `account_tx` for the issuer captures **all** activity for that token — trades, payments, trustline mods. Costly for high-volume issuers (~5k–10k txs/hour for active tokens) but the only complete on-chain index when you can't use a third-party API.

```js
const params = {account: ISSUER, ledger_index_min:-1, ledger_index_max:-1, limit:400, forward:false, marker};
```

7-day window for an active token = ~50k–150k txs = 125–375 paginated calls at limit=400.

## Distinguish DEX trades from peer-to-peer transfers

A `Payment` can either consume DEX offers OR transfer IOU directly between trust lines. To detect a real DEX fill, scan `meta.AffectedNodes` for `LedgerEntryType: 'Offer'`:

- `ModifiedNode.LedgerEntryType === 'Offer'` with `PreviousFields.TakerGets` or `PreviousFields.TakerPays` → partial fill
- `DeletedNode.LedgerEntryType === 'Offer'` with `PreviousFields` present → full fill (offer consumed to zero)
- `DeletedNode.LedgerEntryType === 'Offer'` **without** `PreviousFields` → cancellation, not a trade

`OfferCreate` txs are always DEX activity; `Payment` txs only count if at least one Offer node was touched.

## Trust-line delta interpretation

For each `RippleState` `ModifiedNode`/`CreatedNode`/`DeletedNode`:

```js
const delta = parseFloat(FinalFields.Balance.value) - parseFloat(PreviousFields.Balance?.value ?? FinalFields.Balance.value);
```

**Gross volume (sum-abs):** every trade leg modifies trust lines on both counterparties → summing `|delta|` across all RippleState nodes for the currency double-counts. Divide by 2 for actual moved amount.

**Signed direction (per wallet):** balance sign depends on which side of the trustline the wallet is on. Determine `LowLimit.issuer` vs `HighLimit.issuer`:

```js
// Wallet received the IOU when:
//   wallet is HighLimit holder AND balance increased (delta > 0)
//   wallet is LowLimit holder AND balance decreased (delta < 0)
const walletDelta = walletIsHigh ? delta : -delta;  // positive = wallet received
```

Forgetting this sign-flip is the most common bug in per-wallet flow analysis.

## Parse offer consumption to attribute maker volume

```js
for (const n of meta.AffectedNodes) {
  if (n.ModifiedNode?.LedgerEntryType === 'Offer') {
    const pf = n.ModifiedNode.PreviousFields, ff = n.ModifiedNode.FinalFields;
    if (!pf.TakerGets && !pf.TakerPays) continue;  // unchanged
    const consumedGets = parseFloat(pf.TakerGets.value ?? ff.TakerGets.value) - parseFloat(ff.TakerGets.value);
    // maker = ff.Account; this is what the maker gave up
  } else if (n.DeletedNode?.LedgerEntryType === 'Offer' && n.DeletedNode.PreviousFields) {
    // entire remaining TakerGets/TakerPays consumed
  }
}
```

Amounts can be XRP (string drops, divide by 1e6) or IOU (object with `value`/`currency`/`issuer`).

## Corridor detection (token-pair filter)

A trade is "in the X↔Y corridor" when the tx's meta moves both tokens (X delta > 0 AND Y delta > 0). Path-based payments via XRP intermediary still count — both ends touch trust lines for X and Y. A pure X↔XRP trade only moves one IOU.

## Skip issuer-direct payments when measuring DEX activity

`Payment` where `tx.Account === issuer` or `tx.Destination === issuer` is issuance/redemption, not a DEX trade. Filter out before counting volume.

## OnTheDEX API limit

OnTheDEX has no per-trade endpoint — only OHLC and aggregates. For individual trade data, use the issuer `account_tx` approach above.

## Cross-Refs

- `dex-data.md` — OnTheDEX API reference and XRPL native DEX protocol mechanics
- `wallet-clustering.md` — funder-trace heuristics for grouping related wallets
- `patterns.md` — orderbook fetching, fill detection
