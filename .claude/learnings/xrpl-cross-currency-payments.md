# XRPL Cross-Currency Payments

## `delivered_amount` in Payment Metadata

`delivered_amount` (in `metaData`) is always available for payments after 2014-01-20. For partial payments, `Amount` is the *maximum* — only `delivered_amount` reflects what was actually received. Always use `delivered_amount` for the actual transfer amount.

## Payment Engine Two-Pass Calculation

Cross-currency payments use a two-pass algorithm:
1. **Reverse pass**: Start from destination amount, work backwards through paths computing how much each step needs (including transfer fees via quality adjustments)
2. **Forward pass**: Start from source, push liquidity forward, constrained by reverse-pass limits

Transfer fees are incorporated in the reverse pass as quality reductions. The forward pass may deliver slightly less than requested due to rounding.

## Pathfinding `source_amount` Includes Transfer Fees

`ripple_path_find` response's `source_amount` already includes transfer fees in the total. No separate fee computation needed — use `source_amount` directly as the `SendMax` basis (with margin for slippage).

## TransferRate Formula

`fee% = ((TransferRate - 1,000,000,000) / 1,000,000,000) * 100`

Range: 0-100% (TransferRate 1,000,000,000 to 2,000,000,000). Set via `AccountSet` with `TransferRate` field. Only the issuer's TransferRate applies; it's charged on every transfer of that issuer's tokens (including DEX trades).

## `tfLimitQuality` Evaluates Per-Step

`tfLimitQuality` flag on Payment transactions evaluates quality (exchange rate) at each individual path step, not the aggregate rate. A payment with 3% aggregate slippage tolerance could still fail if any single step exceeds the limit. Set margins to accommodate the worst single step, not just the overall rate.

## Non-Partial Payment `SendMax` Is a Ceiling

For non-partial payments (no `tfPartialPayment`), `SendMax` is a hard ceiling — the payment either delivers the exact `Amount` spending at most `SendMax`, or fails entirely. Generous margins on `SendMax` are safe because you won't overspend — the exact `Amount` is delivered or nothing. Over-engineering tight `SendMax` values risks unnecessary `tecPATH_PARTIAL` failures.

## NoRipple "Enters AND Exits" Rule

A path is blocked by NoRipple only when it **enters AND exits** an account through trust lines where that account has NoRipple enabled. A single NoRipple trust line does not block a path that only enters or only exits through it. The pathfinding engine (`ripple_path_find`) already excludes NoRipple-blocked paths from results.

## `noripple_check` API Command

Diagnoses misconfigured rippling settings. Takes `account` and `role` parameters:
- `role: "gateway"` — checks if issuer has DefaultRipple enabled and trust lines configured correctly
- `role: "user"` — checks if regular account has NoRipple set appropriately

Useful for diagnosing `tecPATH_DRY` failures caused by rippling misconfiguration.

## DefaultRipple Timing Requirement

`DefaultRipple` flag (set via `AccountSet`) must be enabled on the issuer account **BEFORE** trust lines are created. Enabling it after trust line creation does NOT retroactively update existing trust lines — those lines retain their original rippling settings. To fix: each holder must individually set `tfSetNoRipple` then `tfClearNoRipple` on their trust line, or create new trust lines after the flag is set.
