Identifying related wallets on XRPL via funder tracing, timing correlation, and behavioral fingerprinting.
- **Keywords:** funder, account_tx, clustering, wallet, operator, sybil, arb, market-maker, forensics, funding chain
- **Related:** trade-forensics.md, dex-data.md

---

## Funder trace (strongest signal)

Earliest tx in `account_tx(forward=true, limit=1)` is the funding tx. `tx.Account` = funder. Multi-hop: chain from funder → funder's funder → until reaching an exchange or genesis wallet.

```js
const res = await rpc('account_tx', {account: addr, ledger_index_min:-1, ledger_index_max:-1, limit:1, forward:true});
const funder = res.transactions[0].tx.Account;
```

## Signal strength hierarchy

| Signal | Strength | Notes |
|--------|----------|-------|
| Same funder address | Strong | Rarely coincidence |
| Funded in same ledger by *different* funders | Medium-strong | Coordinated batch — e.g., bot deploying N wallets in one tx burst |
| Funded within minutes by same funder | Strong | Serial batch deploy |
| Identical trust-line limits | Medium | Programmatic setup (`AccountSet` or trustline creation with same limit suggests same template) |
| Same behavior profile (volume, tx cadence, taker/maker ratio) | Weak | Could be same template, different operators |
| Common upstream ancestor at 3+ hops | Weak | Often a shared exchange/on-ramp (Bitstamp, Bitso, Uphold wallets fund many unrelated accounts) |
| Low Jaccard overlap of active ledgers | Neutral/positive | Same operator may *deliberately* avoid same-ledger activity (self-crossing avoidance, rate-limit management) |

## Batch funding patterns

Operators funding multiple wallets often use one of:

1. **Single funder → N wallets** (directly). Easy to detect.
2. **N separate funders → N wallets in same ledger**. Harder — requires checking ledger index of each wallet's first tx. Same-ledger batch with different senders is a strong coordinated-deploy signal.
3. **Daisy-chain: A → B → C → D**. Each wallet funded by the previous. Trace the chain to the root.

## Common operator patterns in DEX corridors

- **Arb bot cluster**: many wallets, high volume, near-zero net position, taker-dominant. Round-trips both directions. Often 5–15 wallets.
- **Maker cluster**: several wallets with high maker fill counts. Often funded by same parent. Volume is ~evenly distributed (load-balancing).
- **Pass-through pipeline**: wallets that buy asset from one source, transfer internally, then sell via a different wallet (sometimes a maker). BBRL balance = 0 despite large gross flows.
- **Dormant deploy**: wallet funded months before activation. Typical for prepared infrastructure — operator creates wallet farm ahead of a market event or strategy launch.

## Upstream convergence ≠ same operator

Funding chains at depth 3+ often converge on exchange hot wallets or old on-ramp accounts. A 2017 wallet that funded 10,000 unrelated wallets is not evidence of shared ownership. Discriminator: dedicated funders (funded few wallets, recently created, minimal other activity) vs hub wallets (funded hundreds, years old, high diverse volume).

## Cross-Refs

- `trade-forensics.md` — parsing DEX trade meta for volume attribution
- `dex-data.md` — XRPL DEX mechanics and data APIs
